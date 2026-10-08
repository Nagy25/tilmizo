import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/student_announcement.dart';
import 'announcement_meta.dart';

/// A read-only feed entry with an unread dot and "new" label. Tapping opens
/// the full announcement.
class StudentAnnouncementCard extends StatelessWidget {
  const StudentAnnouncementCard({
    super.key,
    required this.item,
    required this.onOpen,
  });

  final StudentAnnouncement item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final announcement = item.announcement;
    final textTheme = context.textTheme;
    return TelmizoCard(
      key: Key('student-announcement-${item.id}'),
      padding: EdgeInsets.zero,
      color: item.isUnread
          ? TelmizoColors.primaryTint
          : TelmizoColors.surfaceContainerLowest,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: TelmizoRadius.xlAll,
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(TelmizoSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (item.isUnread) ...[
                      Semantics(
                        label: LocaleKeys.announcements_unread_semantics.tr(),
                        child: Container(
                          key: Key('unread-dot-${item.id}'),
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: TelmizoColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: TelmizoSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: item.isUnread ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                    if (item.isUnread)
                      TelmizoPill(
                        label: LocaleKeys.announcements_new.tr(),
                        background: TelmizoColors.primary,
                        foreground: TelmizoColors.onPrimary,
                      ),
                  ],
                ),
                const SizedBox(height: TelmizoSpacing.sm),
                Text(
                  announcement.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TelmizoSpacing.md),
                AnnouncementMeta(announcement: announcement),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
