import 'package:core_package/core_package.dart';

import '../domain/payment_models.dart';

/// Column and RPC parameter mapping for the Phase 5 payment contract.
abstract final class PaymentsDto {
  static const planColumns =
      'id, group_id, amount, due_day, due_mode, started_month';

  /// Obligations with receipts and the student's display identity, reached
  /// through the obligation's composite membership foreign key.
  static const obligationColumns =
      '${PaymentObligation.columns}, '
      'membership:group_memberships!payment_obligations_membership_fkey('
      'student:profiles!group_memberships_student_id_fkey(full_name, phone))';

  static MonthlyPaymentPlan planFromRow(Map<String, dynamic> row) =>
      MonthlyPaymentPlan(
        id: row['id'] as String,
        groupId: row['group_id'] as String,
        amount: EgpAmount.fromBackend(row['amount']),
        startedMonth: parseCalendarDate(row['started_month'] as String),
        dueDay: (row['due_day'] as num?)?.toInt() ?? 1,
        dueMode: row['due_mode'] == 'join_day'
            ? MonthlyDueMode.joinDay
            : MonthlyDueMode.fixedDay,
      );

  static StudentPaymentRecord recordFromRow(Map<String, dynamic> row) {
    final membership = row['membership'] as Map<String, dynamic>?;
    final student = membership?['student'] as Map<String, dynamic>?;
    return StudentPaymentRecord(
      obligation: PaymentObligation.fromRow(row),
      studentName: trimToNull(student?['full_name'] as String?),
      studentPhone: student?['phone'] as String?,
    );
  }

  /// The three-argument `configure_monthly_payment_plan` overload.
  static Map<String, dynamic> configurePlanParams(
    String groupId,
    EgpAmount amount, {
    required int dueDay,
    MonthlyDueMode dueMode = MonthlyDueMode.fixedDay,
  }) => {
    'p_group_id': groupId,
    'p_amount': amount.toBackend(),
    'p_due_day': dueMode == MonthlyDueMode.joinDay ? null : dueDay,
    'p_due_mode': dueMode == MonthlyDueMode.joinDay ? 'join_day' : 'fixed_day',
  };

  static Map<String, dynamic> oneTimeParams(
    String groupId,
    OneTimePaymentDraft draft,
  ) => {
    'p_group_id': groupId,
    'p_title': draft.title.trim(),
    'p_amount': draft.amount.toBackend(),
    'p_description': trimToNull(draft.description),
  };

  static Map<String, dynamic> attachSessionParams(
    String sessionId,
    EgpAmount amount,
  ) => {'p_session_id': sessionId, 'p_amount': amount.toBackend()};

  static Map<String, dynamic> markPaidParams(
    String obligationId,
    PaymentMethod method,
  ) => {'p_obligation_id': obligationId, 'p_method': method.backendValue};
}
