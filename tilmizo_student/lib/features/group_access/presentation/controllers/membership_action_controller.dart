import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/group_access_repository_impl.dart';
import '../../domain/group_access_entry.dart';
import 'group_access_providers.dart';

enum MembershipAction { requestReplacement, leave, refresh }

@immutable
final class MembershipActionState {
  const MembershipActionState({this.inProgress, this.failure});

  final MembershipAction? inProgress;
  final AppFailureType? failure;

  bool get isBusy => inProgress != null;
}

final membershipActionControllerProvider =
    NotifierProvider.autoDispose<
      MembershipActionController,
      MembershipActionState
    >(MembershipActionController.new);

/// Device replacement, leaving, and explicit status refresh. Ignores a new
/// action while one is pending and always refreshes the overview afterwards.
class MembershipActionController extends Notifier<MembershipActionState> {
  @override
  MembershipActionState build() => const MembershipActionState();

  /// Returns the request status: `approved` when the backend recognized
  /// this installation as the approved device, otherwise `pending`.
  Future<JoinRequestStatus?> requestReplacement(GroupAccessEntry entry) async {
    JoinRequestStatus? status;
    final succeeded = await _run(MembershipAction.requestReplacement, () async {
      final outcome = await ref
          .read(groupAccessRepositoryProvider)
          .requestDeviceReplacement(entry.membershipId!);
      status = outcome.status;
    });
    return succeeded ? status : null;
  }

  Future<bool> leave(GroupAccessEntry entry) => _run(
    MembershipAction.leave,
    () =>
        ref.read(groupAccessRepositoryProvider).leaveGroup(entry.membershipId!),
  );

  Future<bool> refreshStatus() => _run(MembershipAction.refresh, () async {});

  Future<bool> _run(
    MembershipAction action,
    Future<void> Function() body,
  ) async {
    if (state.isBusy) return false;
    state = MembershipActionState(inProgress: action);
    var succeeded = false;
    AppFailureType? failure;
    try {
      await body();
      succeeded = true;
    } on AppFailure catch (error) {
      failure = error.type;
    }
    try {
      await ref.read(groupAccessOverviewProvider.notifier).refresh();
    } on AppFailure catch (error) {
      failure ??= error.type;
      succeeded = false;
    }
    if (ref.mounted) state = MembershipActionState(failure: failure);
    return succeeded;
  }
}
