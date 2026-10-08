import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../group_access/presentation/widgets/approved_group_tab_list.dart';
import '../controllers/student_announcements_providers.dart';
import 'announcement_details_sheet.dart';
import 'student_announcement_card.dart';

/// The approved group's announcements, read-only and newest first.
class StudentAnnouncementsTab extends ConsumerWidget {
  const StudentAnnouncementsTab({
    super.key,
    required this.groupId,
    required this.onRefresh,
  });

  final String groupId;

  /// Refreshes access and every tab of the group screen.
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(studentAnnouncementsProvider(groupId));
    return ApprovedGroupTabList(
      onRefresh: onRefresh,
      children: [
        TelmizoInlineMessage(
          message: LocaleKeys.announcements_intro.tr(),
          tone: TelmizoMessageTone.info,
        ),
        const SizedBox(height: TelmizoSpacing.md),
        ...switch (feed) {
          AsyncData(:final value) when value.items.isEmpty => [
            _Message(
              key: const Key('student-announcements-empty'),
              icon: Icons.campaign_outlined,
              title: LocaleKeys.announcements_empty_title.tr(),
              body: LocaleKeys.announcements_empty_body.tr(),
            ),
          ],
          AsyncData(:final value) => [
            for (final item in value.items) ...[
              StudentAnnouncementCard(
                item: item,
                onOpen: () => showAnnouncementDetails(
                  context,
                  groupId: groupId,
                  item: item,
                ),
              ),
              const SizedBox(height: TelmizoSpacing.md),
            ],
            if (value.hasMore)
              TelmizoSecondaryButton(
                key: const Key('student-announcements-load-more'),
                label: value.loadMoreFailed
                    ? LocaleKeys.announcements_load_more_error.tr()
                    : LocaleKeys.announcements_load_more.tr(),
                isLoading: value.isLoadingMore,
                onPressed: value.isLoadingMore
                    ? null
                    : () => ref
                          .read(studentAnnouncementsProvider(groupId).notifier)
                          .loadMore(),
              ),
          ],
          AsyncError(:final error) => [_error(ref, error)],
          _ => [
            const Padding(
              padding: EdgeInsets.all(TelmizoSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        },
      ],
    );
  }

  Widget _error(WidgetRef ref, Object error) {
    final type = failureTypeOf(error);
    final accessLost = type == AppFailureType.notFound;
    return _Message(
      key: const Key('student-announcements-error'),
      icon: accessLost ? Icons.lock_outline : Icons.cloud_off_outlined,
      title: accessLost
          ? LocaleKeys.announcements_access_lost_title.tr()
          : LocaleKeys.announcements_load_error_title.tr(),
      body: accessLost
          ? LocaleKeys.announcements_access_lost_body.tr()
          : appFailureMessage(type),
      actionLabel: LocaleKeys.common_retry.tr(),
      onAction: () => refreshStudentAnnouncements(ref, groupId),
    );
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
        Text(body, textAlign: TextAlign.center),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}
