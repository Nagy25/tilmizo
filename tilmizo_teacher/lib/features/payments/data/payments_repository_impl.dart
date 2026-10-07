import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/payment_models.dart';
import '../domain/payments_repository.dart';
import 'payments_dto.dart';
import 'payments_remote_data_source.dart';

final paymentsRemoteDataSourceProvider = Provider<PaymentsRemoteDataSource>(
  (ref) => SupabasePaymentsDataSource(ref.watch(supabaseClientProvider)),
);

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepositoryImpl(
    ref.watch(paymentsRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class PaymentsRepositoryImpl implements PaymentsRepository {
  PaymentsRepositoryImpl(this._dataSource, this._auth);

  final PaymentsRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<GroupPayments> fetchGroupPayments(String groupId) => _guard(() async {
    requireUserId(_auth);
    final plan = await _dataSource.fetchActivePlan(groupId);
    final rows = await _dataSource.fetchObligations(groupId);
    return GroupPayments(
      plan: plan == null ? null : PaymentsDto.planFromRow(plan),
      records: rows.map(PaymentsDto.recordFromRow).toList(growable: false),
    );
  });

  @override
  Future<EgpAmount?> fetchSessionPaymentAmount(String sessionId) =>
      _guard(() async {
        requireUserId(_auth);
        final row = await _dataSource.fetchActiveSessionItem(sessionId);
        return row == null ? null : EgpAmount.fromBackend(row['amount']);
      });

  @override
  Future<MonthlyPaymentPlan> configureMonthlyPlan(
    String groupId,
    EgpAmount amount, {
    required int dueDay,
    MonthlyDueMode dueMode = MonthlyDueMode.fixedDay,
  }) => _guard(() async {
    if (dueMode == MonthlyDueMode.fixedDay &&
        (dueDay < MonthlyPaymentPlan.minDueDay ||
            dueDay > MonthlyPaymentPlan.maxDueDay)) {
      throw const AppFailure(AppFailureType.invalidInput);
    }
    final row = await _rpc(
      'configure_monthly_payment_plan',
      PaymentsDto.configurePlanParams(
        groupId,
        amount,
        dueDay: dueDay,
        dueMode: dueMode,
      ),
    );
    return PaymentsDto.planFromRow(row as Map<String, dynamic>);
  });

  @override
  Future<void> stopMonthlyPlan(String groupId) =>
      _guard(() => _rpc('stop_monthly_payment_plan', {'p_group_id': groupId}));

  @override
  Future<void> createOneTimePayment(
    String groupId,
    OneTimePaymentDraft draft,
  ) => _guard(
    () => _rpc(
      'create_one_time_group_payment',
      PaymentsDto.oneTimeParams(groupId, draft),
    ),
  );

  @override
  Future<void> attachSessionPayment(String sessionId, EgpAmount amount) =>
      _guard(
        () => _rpc(
          'attach_session_payment',
          PaymentsDto.attachSessionParams(sessionId, amount),
        ),
      );

  @override
  Future<void> markPaid(String obligationId, PaymentMethod method) => _guard(
    () => _rpc(
      'mark_payment_paid',
      PaymentsDto.markPaidParams(obligationId, method),
    ),
  );

  @override
  Future<void> voidPaidMark(String receiptId) =>
      _guard(() => _rpc('void_paid_payment', {'p_receipt_id': receiptId}));

  Future<Object?> _rpc(String function, Map<String, dynamic> params) {
    requireUserId(_auth);
    return _dataSource.rpc(function, params);
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
