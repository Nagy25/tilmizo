import 'package:core_package/core_package.dart';

/// The signed-in student's own payment records. RLS returns only rows that
/// name this student, including history from groups the student has left.
/// Implementations throw only `AppFailure`.
abstract interface class StudentPaymentsRepository {
  /// Current (unpaid or paid) records, newest first, optionally limited to
  /// [groupId]. Void rows are never returned.
  Future<List<PaymentObligation>> fetchMyPayments({String? groupId});
}
