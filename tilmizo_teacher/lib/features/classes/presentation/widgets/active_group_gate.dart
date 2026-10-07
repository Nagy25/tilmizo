import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';

/// Loads [groupId] and builds [builder] only for an active group, since
/// archived groups cannot receive new schedules or sessions. With
/// [blockSuspended], a suspended group is blocked too.
class ActiveGroupGate extends ConsumerWidget {
  const ActiveGroupGate({
    super.key,
    required this.groupId,
    required this.builder,
    this.archivedMessage,
    this.blockSuspended = false,
    this.suspendedMessage,
  });

  final String groupId;

  /// Shown for archived groups; defaults to the classes notice.
  final String? archivedMessage;

  /// Whether a suspended group, which accepts no new sessions or payment
  /// amounts, is blocked like an archived one.
  final bool blockSuspended;

  /// Shown for blocked suspended groups; defaults to the classes notice.
  final String? suspendedMessage;
  final Widget Function(TeacherGroup group) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupDetailsProvider(groupId));
    return group.when(
      skipLoadingOnRefresh: true,
      loading: () => const TelmizoLoadingView(),
      error: (error, _) {
        final type = failureTypeOf(error);
        return TelmizoErrorView(
          icon: type == AppFailureType.notFound
              ? Icons.search_off
              : Icons.cloud_off_outlined,
          title: type == AppFailureType.notFound
              ? LocaleKeys.group_not_found_title.tr()
              : LocaleKeys.groups_load_error_title.tr(),
          message: appFailureMessage(type),
          retryLabel: LocaleKeys.common_retry.tr(),
          onRetry: () => ref.invalidate(groupDetailsProvider(groupId)),
        );
      },
      data: (group) {
        if (!group.isActive) {
          return TelmizoErrorView(
            icon: Icons.lock_outline,
            title: LocaleKeys.group_status_inactive.tr(),
            message: archivedMessage ?? LocaleKeys.classes_archived_notice.tr(),
            retryLabel: LocaleKeys.common_back.tr(),
            onRetry: () => context.router.maybePop(),
          );
        }
        if (blockSuspended && group.isSuspended) {
          return TelmizoErrorView(
            key: const Key('group-suspended-gate'),
            icon: Icons.pause_circle_outline,
            title: LocaleKeys.group_status_suspended.tr(),
            message:
                suspendedMessage ?? LocaleKeys.classes_suspended_notice.tr(),
            retryLabel: LocaleKeys.common_back.tr(),
            onRetry: () => context.router.maybePop(),
          );
        }
        return builder(group);
      },
    );
  }
}
