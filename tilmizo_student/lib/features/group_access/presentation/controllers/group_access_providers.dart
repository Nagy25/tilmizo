import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/group_access_repository_impl.dart';
import '../../domain/approved_group.dart';
import '../../domain/group_access_entry.dart';
import '../../domain/student_access_state.dart';

/// The backend's view of every group the student requested or joined. This
/// is the authority for routing; local state never grants access.
final groupAccessOverviewProvider =
    AsyncNotifierProvider<
      GroupAccessOverviewController,
      List<GroupAccessEntry>
    >(GroupAccessOverviewController.new);

class GroupAccessOverviewController
    extends AsyncNotifier<List<GroupAccessEntry>> {
  @override
  Future<List<GroupAccessEntry>> build() =>
      ref.watch(groupAccessRepositoryProvider).fetchOverview();

  Future<List<GroupAccessEntry>> refresh() async {
    ref.invalidateSelf();
    return future;
  }
}

/// The overview entry for one group, or null when it no longer exists.
GroupAccessEntry? findEntry(List<GroupAccessEntry> entries, String groupId) {
  for (final entry in entries) {
    if (entry.groupId == groupId) return entry;
  }
  return null;
}

/// Waits for the access overview and fails unless this session is approved
/// for [groupId]. Watching it drops a group-scoped provider's data as soon
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

/// Group details, fetched only while the overview says this session is
/// approved. When access is replaced, suspended, or removed, the overview
/// changes and this provider drops its cached data immediately.
final approvedGroupProvider = FutureProvider.autoDispose
    .family<ApprovedGroup, String>((ref, groupId) async {
      await requireApprovedAccess(ref, groupId);
      return ref
          .watch(groupAccessRepositoryProvider)
          .fetchApprovedGroup(groupId);
    });

/// This device's display information, as the teacher will see it.
final deviceDisplayInfoProvider = FutureProvider<DeviceDisplayInfo>(
  (ref) => ref.watch(deviceInfoServiceProvider).load(),
);

/// Refreshes the overview on every Realtime change while watched.
final studentAccessLiveUpdatesProvider = Provider.autoDispose<void>((ref) {
  final subscription = ref
      .watch(groupAccessRepositoryProvider)
      .watchMyAccess()
      .listen(
        (_) => ref.invalidate(groupAccessOverviewProvider),
        onError: (_) {},
      );
  ref.onDispose(subscription.cancel);
});
