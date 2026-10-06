import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../group_access/domain/student_access_state.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../data/student_classes_repository_impl.dart';
import '../../domain/student_class.dart';

typedef StudentPageRequest = ({
  StudentSessionsView view,
  String? groupId,
  int offset,
  int limit,
});

final studentSessionsPageProvider = FutureProvider.autoDispose
    .family<StudentSessionsPage, StudentPageRequest>((ref, request) async {
      final ids = await _approvedIds(ref);
      return ref
          .watch(studentClassesRepositoryProvider)
          .fetchSessions(
            approvedGroupIds: ids,
            groupId: request.groupId,
            view: request.view,
            now: DateTime.now(),
            offset: request.offset,
            limit: request.limit,
          );
    });

final studentClassSessionProvider = FutureProvider.autoDispose
    .family<StudentClassSession, String>((ref, sessionId) async {
      final ids = await _approvedIds(ref);
      return ref
          .watch(studentClassesRepositoryProvider)
          .fetchSession(sessionId: sessionId, approvedGroupIds: ids);
    });

final studentScheduleProvider = FutureProvider.autoDispose
    .family<List<StudentScheduleEntry>, String>((ref, groupId) async {
      final ids = await _approvedIds(ref);
      if (!ids.contains(groupId)) {
        throw const AppFailure(AppFailureType.notFound);
      }
      return ref.watch(studentClassesRepositoryProvider).fetchSchedule(groupId);
    });

final studentGroupActivityProvider =
    FutureProvider.autoDispose<Map<String, bool>>((ref) async {
      final ids = await _approvedIds(ref);
      return ref
          .watch(studentClassesRepositoryProvider)
          .fetchGroupActivity(ids);
    });

Future<List<String>> _approvedIds(Ref ref) async {
  final entries = await ref.watch(groupAccessOverviewProvider.future);
  return [
    for (final entry in entries)
      if (entry.state == StudentAccessState.approved) entry.groupId,
  ];
}

void refreshStudentClasses(WidgetRef ref) {
  ref.invalidate(studentSessionsPageProvider);
  ref.invalidate(studentClassSessionProvider);
  ref.invalidate(studentScheduleProvider);
  ref.invalidate(studentGroupActivityProvider);
}
