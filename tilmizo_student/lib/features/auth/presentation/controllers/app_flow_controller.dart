import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../group_access/domain/group_access_entry.dart';
import '../../../group_access/domain/student_access_state.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../../profile/presentation/controllers/current_profile_controller.dart';
import '../../domain/student_destination.dart';

/// Resolves the student's destination from the backend: session, profile,
/// then the access overview. Throws [AppFailure] when it cannot be resolved
/// yet, such as offline.
Future<StudentFlowResult> resolveStudentFlow(Ref ref) async {
  final auth = ref.read(phoneAuthServiceProvider);
  if (!auth.isAuthenticated) {
    return const StudentFlowResult(StudentDestination.phoneLogin);
  }

  try {
    final profile = await ref.read(currentProfileProvider.future);
    if (!profile.isComplete) {
      return const StudentFlowResult(StudentDestination.completeProfile);
    }

    return flowForEntries(await ref.read(groupAccessOverviewProvider.future));
  } on AppFailure catch (failure) {
    if (failure.type != AppFailureType.sessionExpired) rethrow;
    try {
      await auth.signOut();
    } on AuthFailure {
      // Already unusable; continue to login.
    }
    return const StudentFlowResult(StudentDestination.phoneLogin);
  }
}

/// Destination for a student with a complete profile and these groups.
StudentFlowResult flowForEntries(List<GroupAccessEntry> entries) {
  if (entries.isEmpty) {
    return const StudentFlowResult(StudentDestination.emptyGroups);
  }
  final single = entries.length == 1 ? entries.single : null;
  return StudentFlowResult(
    StudentDestination.groupsHome,
    focus: single != null && single.state != StudentAccessState.approved
        ? single
        : null,
  );
}

/// Clears cached student data so the next read reflects the current session.
final resetSessionDataProvider = Provider<void Function()>(
  (ref) => () {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(groupAccessOverviewProvider);
    ref.invalidate(approvedGroupProvider);
  },
);

final appStartupProvider = FutureProvider.autoDispose<StudentFlowResult>(
  resolveStudentFlow,
);
