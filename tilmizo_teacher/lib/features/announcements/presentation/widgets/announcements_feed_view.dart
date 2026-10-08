import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../groups/domain/teacher_group.dart';
import '../announcement_labels.dart';
import '../controllers/announcements_providers.dart';
import 'announcement_card.dart';
import 'delete_announcement_dialog.dart';

/// A group's announcements, newest first. Publish and delete appear only
/// while the group accepts new entries; archived and suspended feeds stay
/// readable. There is no edit.
class AnnouncementsFeedView extends ConsumerWidget {
  const AnnouncementsFeedView({
    super.key,
    required this.group,
    required this.onAdd,
  });

  final TeacherGroup group;
  final VoidCallback onAdd;

  String get _groupId => group.id;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Announcement announcement,
  ) async {
    final confirmed = await confirmAnnouncementDelete(context, announcement);
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(announcementsFeedProvider(_groupId).notifier)
          .delete(announcement.id);
      if (context.mounted) {
        showTelmizoSnackBar(context, LocaleKeys.announcement_deleted.tr());
      }
    } on AppFailure catch (failure) {
      if (context.mounted) {
        showTelmizoSnackBar(context, announcementFailureMessage(failure));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(announcementsFeedProvider(_groupId));
    final canManage = group.acceptsNewEntries;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(announcementsFeedProvider(_groupId).notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          TelmizoSpacing.md,
          TelmizoSpacing.margin,
          TelmizoSpacing.xxl * 2,
        ),
        children: [
          if (!canManage) ...[
            TelmizoInlineMessage(
              key: const Key('announcements-read-only'),
              message: group.isActive
                  ? LocaleKeys.announcements_suspended_notice.tr()
                  : LocaleKeys.announcements_archived_notice.tr(),
              tone: TelmizoMessageTone.info,
            ),
            const SizedBox(height: TelmizoSpacing.lg),
          ],
          ...switch (feed) {
            AsyncData(:final value) => _content(context, ref, value, canManage),
            AsyncError(:final error) => [
              _Message(
                key: const Key('announcements-error'),
                icon: Icons.cloud_off_outlined,
                title: LocaleKeys.announcements_load_error_title.tr(),
                body: appFailureMessage(failureTypeOf(error)),
                actionLabel: LocaleKeys.common_retry.tr(),
                onAction: () =>
                    ref.invalidate(announcementsFeedProvider(_groupId)),
              ),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(TelmizoSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    AnnouncementsFeedState state,
    bool canManage,
  ) {
    if (state.announcements.isEmpty) {
      return [
        _Message(
          key: const Key('announcements-empty'),
          icon: Icons.campaign_outlined,
          title: LocaleKeys.announcements_empty_title.tr(),
          body: canManage
              ? LocaleKeys.announcements_empty_body.tr()
              : LocaleKeys.announcements_empty_read_only_body.tr(),
          actionLabel: canManage ? LocaleKeys.announcements_add.tr() : null,
          onAction: canManage ? onAdd : null,
        ),
      ];
    }
    return [
      for (final announcement in state.announcements) ...[
        AnnouncementCard(
          announcement: announcement,
          canManage: canManage,
          onDelete: () => _delete(context, ref, announcement),
        ),
        const SizedBox(height: TelmizoSpacing.md),
      ],
      if (state.hasMore) ...[
        if (state.loadMoreFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: TelmizoSpacing.sm),
            child: Text(
              LocaleKeys.announcements_load_more_error.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: TelmizoColors.error),
            ),
          ),
        TelmizoSecondaryButton(
          key: const Key('announcements-load-more'),
          label: LocaleKeys.announcements_load_more.tr(),
          isLoading: state.isLoadingMore,
          onPressed: state.isLoadingMore
              ? null
              : () => ref
                    .read(announcementsFeedProvider(_groupId).notifier)
                    .loadMore(),
        ),
      ],
    ];
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Column(
      children: [
        Icon(icon, size: 40, color: TelmizoColors.onSurfaceVariant),
        const SizedBox(height: TelmizoSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: TelmizoSpacing.xs),
        Text(
          body,
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: TelmizoColors.onSurfaceVariant,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: TelmizoSpacing.md),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}
