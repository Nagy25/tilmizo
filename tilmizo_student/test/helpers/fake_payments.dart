import 'package:core_package/core_package.dart';
import 'package:tilmizo_student/features/payments/domain/student_payments_repository.dart';

import 'fakes.dart';

PaymentObligation buildObligation({
  String id = 'o1',
  String groupId = 'group-1',
  String studentId = testUserId,
  PaymentSourceType source = PaymentSourceType.oneTime,
  String title = 'مذكرة الفصل الأول',
  int piasters = 15000,
  PaymentStatus status = PaymentStatus.unpaid,
  PaymentMethod method = PaymentMethod.cash,
}) => PaymentObligation(
  id: id,
  groupId: groupId,
  studentId: studentId,
  sourceType: source,
  title: title,
  amount: EgpAmount.piasters(piasters),
  dueOn: DateTime.utc(2026, 10),
  periodMonth: source == PaymentSourceType.monthly
      ? DateTime.utc(2026, 10)
      : null,
  status: status,
  receipt: status == PaymentStatus.paid
      ? PaymentReceipt(
          id: 'r-$id',
          method: method,
          recordedAt: DateTime.utc(2026, 10, 2, 8),
        )
      : null,
);

/// RLS-like fake: returns only the signed-in student's non-void rows, with
/// no dependency on current group access.
final class FakeStudentPaymentsRepository implements StudentPaymentsRepository {
  final obligations = <PaymentObligation>[];
  AppFailure? failure;
  final fetches = <String?>[];

  @override
  Future<List<PaymentObligation>> fetchMyPayments({String? groupId}) async {
    fetches.add(groupId);
    if (failure case final failure?) throw failure;
    return [
      for (final obligation in obligations)
        if (obligation.studentId == testUserId &&
            obligation.status != PaymentStatus.voided &&
            (groupId == null || obligation.groupId == groupId))
          obligation,
    ];
  }
}
