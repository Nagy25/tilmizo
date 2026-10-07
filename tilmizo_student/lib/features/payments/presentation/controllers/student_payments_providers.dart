import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/student_payments_repository_impl.dart';

/// The student's own current records for one group, or across every group
/// when the key is null. Not gated on group access, so history stays
/// readable after leaving a group.
final studentPaymentsProvider = FutureProvider.autoDispose
    .family<List<PaymentObligation>, String?>(
      (ref, groupId) => ref
          .watch(studentPaymentsRepositoryProvider)
          .fetchMyPayments(groupId: groupId),
    );

/// Reloads payment records, for example when the tab opens, on
/// pull-to-refresh, or when the app resumes.
void refreshStudentPayments(WidgetRef ref, String? groupId) {
  ref.invalidate(studentPaymentsProvider(groupId));
  if (groupId != null) ref.invalidate(studentPaymentsProvider(null));
}
