import 'package:flutter/material.dart';

import '../../design_system/telmizo_colors.dart';
import '../../design_system/telmizo_radius.dart';
import '../../design_system/telmizo_spacing.dart';
import '../../helpers/context_extensions.dart';
import '../app_notification.dart';

/// One notification-center row. Unread rows are tinted, bold, and marked
/// with a dot, and offer an individual mark-read action.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.timestamp,
    required this.unreadLabel,
    required this.markReadLabel,
    required this.onTap,
    required this.onMarkRead,
  });

  final AppNotification notification;

  /// The localized, relative creation time.
  final String timestamp;

  /// Announced before the title of an unread row.
  final String unreadLabel;
  final String markReadLabel;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final textTheme = context.textTheme;
    final (icon, foreground, background) = notificationVisuals(
      notification.eventType,
    );
    return Semantics(
      container: true,
      label: unread ? unreadLabel : null,
      child: Material(
        color: unread
            ? TelmizoColors.surfaceContainerLow
            : TelmizoColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: TelmizoRadius.mdAll,
          side: BorderSide(
            color: unread ? TelmizoColors.primaryTint : TelmizoColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              TelmizoSpacing.md,
              TelmizoSpacing.md,
              TelmizoSpacing.xs,
              TelmizoSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: TelmizoRadius.smAll,
                  ),
                  child: Icon(icon, color: foreground, size: 22),
                ),
                const SizedBox(width: TelmizoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: TelmizoColors.onSurface,
                        ),
                      ),
                      if (notification.body case final body?) ...[
                        const SizedBox(height: TelmizoSpacing.xs),
                        Text(
                          body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: TelmizoColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: TelmizoSpacing.sm),
                      Text(
                        timestamp,
                        style: textTheme.labelMedium?.copyWith(
                          color: unread
                              ? TelmizoColors.primary
                              : TelmizoColors.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  IconButton(
                    tooltip: markReadLabel,
                    onPressed: onMarkRead,
                    icon: const _UnreadDot(),
                  )
                else
                  const SizedBox(width: TelmizoSpacing.minTouchTarget),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: const BoxDecoration(
      color: TelmizoColors.primary,
      shape: BoxShape.circle,
    ),
  );
}

/// Icon and colors for an event type, shared with in-app indications.
(IconData, Color, Color) notificationVisuals(NotificationEventType type) =>
    switch (type) {
      NotificationEventType.homeworkNew ||
      NotificationEventType.homeworkDueSoon => (
        Icons.assignment_outlined,
        TelmizoColors.secondary,
        TelmizoColors.secondaryContainer,
      ),
      NotificationEventType.announcementNew => (
        Icons.campaign_outlined,
        TelmizoColors.primary,
        TelmizoColors.primaryTint,
      ),
      NotificationEventType.resourceNew => (
        Icons.folder_outlined,
        TelmizoColors.primary,
        TelmizoColors.primaryTint,
      ),
      NotificationEventType.sessionCancelled => (
        Icons.event_busy_outlined,
        TelmizoColors.error,
        TelmizoColors.errorContainer,
      ),
      NotificationEventType.sessionRescheduled ||
      NotificationEventType.sessionUpcoming => (
        Icons.event_outlined,
        TelmizoColors.secondary,
        TelmizoColors.secondaryContainer,
      ),
      NotificationEventType.paymentOverdue => (
        Icons.payments_outlined,
        TelmizoColors.error,
        TelmizoColors.errorContainer,
      ),
      NotificationEventType.paymentChargeNew => (
        Icons.payments_outlined,
        TelmizoColors.tertiary,
        TelmizoColors.tertiaryContainer,
      ),
      NotificationEventType.paymentRecorded => (
        Icons.check_circle_outline,
        TelmizoColors.success,
        TelmizoColors.successContainer,
      ),
      NotificationEventType.unknown => (
        Icons.notifications_none_outlined,
        TelmizoColors.onSurfaceVariant,
        TelmizoColors.surfaceContainer,
      ),
    };
