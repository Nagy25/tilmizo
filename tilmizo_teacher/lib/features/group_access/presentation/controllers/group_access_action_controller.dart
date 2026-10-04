import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/group_access_repository_impl.dart';
import '../../domain/access_decision_result.dart';
import '../../domain/group_member.dart';
import '../../domain/student_join_request.dart';
import 'group_access_providers.dart';

enum GroupAccessAction { approve, reject, suspend }

@immutable
final class GroupAccessActionState {
  const GroupAccessActionState({this.inProgress, this.failure});

  final GroupAccessAction? inProgress;
  final AppFailureType? failure;

  bool get isBusy => inProgress != null;
}

final groupAccessActionControllerProvider =
    NotifierProvider.autoDispose<
      GroupAccessActionController,
      GroupAccessActionState
    >(GroupAccessActionController.new);

/// Approve, reject, and suspend actions. A second action is ignored while
/// one is pending, and every success refreshes the group's access data.
class GroupAccessActionController extends Notifier<GroupAccessActionState> {
  @override
  GroupAccessActionState build() => const GroupAccessActionState();

  Future<AccessDecisionResult?> decide(
    StudentJoinRequest request, {
    required bool approve,
  }) => _run(
    approve ? GroupAccessAction.approve : GroupAccessAction.reject,
    request.groupId,
    () => ref
        .read(groupAccessRepositoryProvider)
        .decide(request.id, approve: approve),
  );

  Future<bool> suspend(GroupMember member) async {
    final done = await _run(
      GroupAccessAction.suspend,
      member.groupId,
      () async {
        await ref
            .read(groupAccessRepositoryProvider)
            .suspend(member.membershipId);
        return true;
      },
    );
    return done ?? false;
  }

  Future<T?> _run<T>(
    GroupAccessAction action,
    String groupId,
    Future<T> Function() body,
  ) async {
    if (state.isBusy) return null;
    state = GroupAccessActionState(inProgress: action);
    try {
      final result = await body();
      if (ref.mounted) state = const GroupAccessActionState();
      return result;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = GroupAccessActionState(failure: failure.type);
      return null;
    } finally {
      // Refresh after success and failure alike: a failure often means the
      // request or membership changed elsewhere.
      if (ref.mounted) refreshGroupAccess(ref, groupId);
    }
  }
}
