import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/payments_repository_impl.dart';
import '../../domain/payment_models.dart';
import '../../domain/payments_repository.dart';

/// The active plan and current records of a group.
final groupPaymentsProvider = FutureProvider.autoDispose
    .family<GroupPayments, String>(
      (ref, groupId) =>
          ref.watch(paymentsRepositoryProvider).fetchGroupPayments(groupId),
    );

/// The active amount attached to a session, or null.
final sessionPaymentAmountProvider = FutureProvider.autoDispose
    .family<EgpAmount?, String>(
      (ref, sessionId) => ref
          .watch(paymentsRepositoryProvider)
          .fetchSessionPaymentAmount(sessionId),
    );

enum PaymentAction {
  configurePlan,
  stopPlan,
  createOneTime,
  attachSession,
  markPaid,
  voidPaid,
}

@immutable
final class PaymentActionsState {
  const PaymentActionsState({this.pending, this.targetId, this.failure});

  final PaymentAction? pending;

  /// The obligation or receipt the pending row action applies to.
  final String? targetId;
  final AppFailureType? failure;

  bool get isBusy => pending != null;

  bool isRunning(PaymentAction action, [String? id]) =>
      pending == action && (id == null || targetId == id);
}

final paymentActionsControllerProvider =
    NotifierProvider.autoDispose<PaymentActionsController, PaymentActionsState>(
      PaymentActionsController.new,
    );

/// Payment RPC writes for one screen. Each method returns whether it
/// succeeded and records a failure in [PaymentActionsState.failure].
class PaymentActionsController extends Notifier<PaymentActionsState> {
  @override
  PaymentActionsState build() => const PaymentActionsState();

  PaymentsRepository get _repository => ref.read(paymentsRepositoryProvider);

  Future<bool> configurePlan(
    String groupId,
    EgpAmount amount, {
    required int dueDay,
    MonthlyDueMode dueMode = MonthlyDueMode.fixedDay,
  }) => _run(
    PaymentAction.configurePlan,
    groupId: groupId,
    () => _repository.configureMonthlyPlan(
      groupId,
      amount,
      dueDay: dueDay,
      dueMode: dueMode,
    ),
  );

  Future<bool> stopPlan(String groupId) => _run(
    PaymentAction.stopPlan,
    groupId: groupId,
    () => _repository.stopMonthlyPlan(groupId),
  );

  Future<bool> createOneTime(String groupId, OneTimePaymentDraft draft) => _run(
    PaymentAction.createOneTime,
    groupId: groupId,
    () => _repository.createOneTimePayment(groupId, draft),
  );

  Future<bool> attachSession({
    required String groupId,
    required String sessionId,
    required EgpAmount amount,
  }) async {
    final container = ref.container;
    final attached = await _run(
      PaymentAction.attachSession,
      groupId: groupId,
      () => _repository.attachSessionPayment(sessionId, amount),
    );
    container.invalidate(sessionPaymentAmountProvider(sessionId));
    return attached;
  }

  Future<bool> markPaid(PaymentObligation obligation, PaymentMethod method) =>
      _run(
        PaymentAction.markPaid,
        groupId: obligation.groupId,
        targetId: obligation.id,
        () => _repository.markPaid(obligation.id, method),
      );

  Future<bool> voidPaid(PaymentObligation obligation) async {
    final receipt = obligation.receipt;
    if (receipt == null) return false;
    return _run(
      PaymentAction.voidPaid,
      groupId: obligation.groupId,
      targetId: obligation.id,
      () => _repository.voidPaidMark(receipt.id),
    );
  }

  void clearFailure() {
    if (state.failure != null && !state.isBusy) {
      state = const PaymentActionsState();
    }
  }

  Future<bool> _run(
    PaymentAction action,
    Future<void> Function() write, {
    required String groupId,
    String? targetId,
  }) async {
    if (state.isBusy) return false;
    final container = ref.container;
    state = PaymentActionsState(pending: action, targetId: targetId);
    try {
      await write();
      if (ref.mounted) state = const PaymentActionsState();
      return true;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = PaymentActionsState(failure: failure.type);
      return false;
    } finally {
      // A rejected write may still mean the server state moved on, for
      // example a record another device already marked paid.
      container.invalidate(groupPaymentsProvider(groupId));
    }
  }
}
