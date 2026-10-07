import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../group_access/domain/student_access_state.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../data/student_resources_repository_impl.dart';

/// Waits for the access overview and fails unless this session is approved
/// for [groupId]. Watching it drops every resource provider's data as soon
/// as access is suspended, removed or replaced.
Future<void> requireApprovedAccess(Ref ref, String groupId) async {
  final approved = await ref.watch(
    groupAccessOverviewProvider.selectAsync(
      (entries) =>
          findEntry(entries, groupId)?.state == StudentAccessState.approved,
    ),
  );
  if (!approved) throw const AppFailure(AppFailureType.notFound);
}

@immutable
final class StudentResourcesState {
  const StudentResourcesState({
    required this.resources,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<GroupResource> resources;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
}

final studentResourcesProvider = AsyncNotifierProvider.autoDispose
    .family<StudentResourcesController, StudentResourcesState, String>(
      StudentResourcesController.new,
    );

class StudentResourcesController extends AsyncNotifier<StudentResourcesState> {
  StudentResourcesController(this.groupId);

  static const pageSize = 30;

  final String groupId;

  @override
  Future<StudentResourcesState> build() async {
    await requireApprovedAccess(ref, groupId);
    final page = await ref
        .watch(studentResourcesRepositoryProvider)
        .fetchResources(groupId, limit: pageSize);
    return StudentResourcesState(
      resources: page.resources,
      hasMore: page.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      StudentResourcesState(
        resources: current.resources,
        hasMore: true,
        isLoadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(studentResourcesRepositoryProvider)
          .fetchResources(
            groupId,
            offset: current.resources.length,
            limit: pageSize,
          );
      if (!ref.mounted) return;
      final known = {for (final resource in current.resources) resource.id};
      state = AsyncData(
        StudentResourcesState(
          resources: [
            ...current.resources,
            ...page.resources.where((r) => !known.contains(r.id)),
          ],
          hasMore: page.hasMore,
        ),
      );
    } on AppFailure {
      if (!ref.mounted) return;
      state = AsyncData(
        StudentResourcesState(
          resources: current.resources,
          hasMore: true,
          loadMoreFailed: true,
        ),
      );
    }
  }
}

final studentResourceCountsProvider = FutureProvider.autoDispose
    .family<Map<ResourceType, int>, String>((ref, groupId) async {
      await requireApprovedAccess(ref, groupId);
      return ref
          .watch(studentResourcesRepositoryProvider)
          .fetchTypeCounts(groupId);
    });

final studentResourceSessionsProvider = FutureProvider.autoDispose
    .family<List<ResourceSessionOption>, String>((ref, groupId) async {
      await requireApprovedAccess(ref, groupId);
      return ref
          .watch(studentResourcesRepositoryProvider)
          .fetchSessions(groupId);
    });

/// Reloads a group's resource views, for example on pull-to-refresh, when
/// the tab opens, or when the student returns to the group.
void refreshStudentResources(WidgetRef ref, String groupId) {
  ref.invalidate(studentResourcesProvider(groupId));
  ref.invalidate(studentResourceCountsProvider(groupId));
  ref.invalidate(studentResourceSessionsProvider(groupId));
}

/// Re-checks access with the backend right before a preview or download; a
/// previously loaded list is not treated as continuing authorization.
Future<bool> confirmResourceAccess(WidgetRef ref, String groupId) async {
  final entries = await ref
      .read(groupAccessOverviewProvider.notifier)
      .refresh();
  return findEntry(entries, groupId)?.state == StudentAccessState.approved;
}
