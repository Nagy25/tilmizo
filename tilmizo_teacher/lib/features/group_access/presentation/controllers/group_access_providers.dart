import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/group_access_repository_impl.dart';
import '../../domain/group_member.dart';
import '../../domain/student_join_request.dart';

final pendingJoinRequestsProvider = FutureProvider.autoDispose
    .family<List<StudentJoinRequest>, String>(
      (ref, groupId) => ref
          .watch(groupAccessRepositoryProvider)
          .fetchPendingRequests(groupId),
    );

final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMember>, String>(
      (ref, groupId) =>
          ref.watch(groupAccessRepositoryProvider).fetchMembers(groupId),
    );

final joinRequestDetailsProvider = FutureProvider.autoDispose
    .family<StudentJoinRequest, String>(
      (ref, requestId) =>
          ref.watch(groupAccessRepositoryProvider).fetchRequest(requestId),
    );

final groupMemberDetailsProvider = FutureProvider.autoDispose
    .family<GroupMember, String>(
      (ref, membershipId) =>
          ref.watch(groupAccessRepositoryProvider).fetchMember(membershipId),
    );

/// Reloads every request and member view of [groupId].
void refreshGroupAccess(Ref ref, String groupId) {
  ref.invalidate(pendingJoinRequestsProvider(groupId));
  ref.invalidate(groupMembersProvider(groupId));
  ref.invalidate(joinRequestDetailsProvider);
  ref.invalidate(groupMemberDetailsProvider);
}

/// Subscribes to Realtime changes for [groupId] while watched, refreshing the
/// access views on every change. The channel is removed on dispose.
final groupAccessLiveUpdatesProvider = Provider.autoDispose
    .family<void, String>((ref, groupId) {
      final subscription = ref
          .watch(groupAccessRepositoryProvider)
          .watchGroup(groupId)
          .listen((_) => refreshGroupAccess(ref, groupId), onError: (_) {});
      ref.onDispose(subscription.cancel);
    });
