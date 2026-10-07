import 'package:core_package/core_package.dart';

import 'payment_models.dart';

/// Payment records of groups owned by the authenticated teacher. Reads use
/// RLS-protected tables; every write goes through a deployed teacher RPC.
/// Implementations throw only `AppFailure`.
abstract interface class PaymentsRepository {
  /// The active monthly plan and the current records of [groupId].
  Future<GroupPayments> fetchGroupPayments(String groupId);

  /// The active amount attached to [sessionId], or null when it has none.
  Future<EgpAmount?> fetchSessionPaymentAmount(String sessionId);

  /// Starts the monthly plan, or changes the active plan's amount and due
  /// day ([MonthlyPaymentPlan.minDueDay]–[MonthlyPaymentPlan.maxDueDay]).
  Future<MonthlyPaymentPlan> configureMonthlyPlan(
    String groupId,
    EgpAmount amount, {
    required int dueDay,
    MonthlyDueMode dueMode = MonthlyDueMode.fixedDay,
  });

  /// Stops the active monthly plan. Existing records are kept.
  Future<void> stopMonthlyPlan(String groupId);

  Future<void> createOneTimePayment(String groupId, OneTimePaymentDraft draft);

  /// Attaches an amount to an existing session, once.
  Future<void> attachSessionPayment(String sessionId, EgpAmount amount);

  /// Marks an unpaid record paid in full.
  Future<void> markPaid(String obligationId, PaymentMethod method);

  /// Voids a paid mark; the receipt stays for audit.
  Future<void> voidPaidMark(String receiptId);
}
