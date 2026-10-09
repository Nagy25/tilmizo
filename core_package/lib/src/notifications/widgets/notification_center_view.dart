import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/telmizo_colors.dart';
import '../../design_system/telmizo_feedback.dart';
import '../../design_system/telmizo_spacing.dart';
import '../../errors/app_failure.dart';
import '../../helpers/context_extensions.dart';
import '../../widgets/telmizo_snack_bar.dart';
import '../app_notification.dart';
import '../notification_center_controller.dart';
import 'notification_permission_card.dart';
import 'notification_tile.dart';

/// Localized text for [NotificationCenterView].
@immutable
final class NotificationCenterLabels {
  const NotificationCenterLabels({
    required this.emptyTitle,
    required this.emptyBody,
    required this.errorTitle,
    required this.retry,
    required this.markAllRead,
    required this.markRead,
    required this.markReadFailed,
    required this.unread,
    required this.loadMoreFailed,
    required this.errorMessage,
    required this.timestamp,
    required this.permission,
  });

  final String emptyTitle;
  final String emptyBody;
  final String errorTitle;
  final String retry;
  final String markAllRead;
  final String markRead;
  final String markReadFailed;
  final String unread;
  final String loadMoreFailed;
  final String Function(Object error) errorMessage;
  final String Function(DateTime createdAt) timestamp;
  final NotificationPermissionLabels permission;
}

/// The notification center body: newest first, paged as the list scrolls,
/// with pull-to-refresh, per-row and bulk mark-read, and permission
/// guidance above the list.
class NotificationCenterView extends ConsumerWidget {
  const NotificationCenterView({
    super.key,
    required this.labels,
    required this.onOpen,
  });

  final NotificationCenterLabels labels;

  /// Called after a row is tapped; the row is marked read first.
  final Future<void> Function(AppNotification notification) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(notificationCenterProvider)
        .when(
          skipLoadingOnRefresh: true,
          loading: () => const TelmizoLoadingView(),
          error: (error, _) => TelmizoErrorView(
            title: labels.errorTitle,
            message: labels.errorMessage(error),
            retryLabel: labels.retry,
            onRetry: () => ref.invalidate(notificationCenterProvider),
          ),
          data: (state) =>
              _CenterList(state: state, labels: labels, onOpen: onOpen),
        );
  }
}

class _CenterList extends ConsumerWidget {
  const _CenterList({
    required this.state,
    required this.labels,
    required this.onOpen,
  });

  final NotificationCenterState state;
  final NotificationCenterLabels labels;
  final Future<void> Function(AppNotification notification) onOpen;

  NotificationCenterController _controller(WidgetRef ref) =>
      ref.read(notificationCenterProvider.notifier);

  Future<void> _mark(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on AppFailure {
      if (context.mounted) showTelmizoSnackBar(context, labels.markReadFailed);
    }
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    // Opening still works when marking read fails, for example offline.
    if (!notification.isRead) {
      try {
        await _controller(ref).markRead(notification.id);
      } on AppFailure {
        // The row stays unread; the badge reloads on the next refresh.
      }
    }
    await onOpen(notification);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = state.notifications;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400 &&
            state.hasMore &&
            !state.isLoadingMore &&
            !state.loadMoreFailed) {
          _controller(ref).loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _controller(ref).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            TelmizoSpacing.margin,
            TelmizoSpacing.md,
            TelmizoSpacing.margin,
            TelmizoSpacing.xl,
          ),
          children: [
            NotificationPermissionCard(labels: labels.permission),
            if (state.hasUnread)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  key: const Key('notifications-mark-all-read'),
                  onPressed: () =>
                      _mark(context, () => _controller(ref).markAllRead()),
                  icon: const Icon(Icons.done_all),
                  label: Text(labels.markAllRead),
                ),
              )
            else
              const SizedBox(height: TelmizoSpacing.md),
            if (items.isEmpty)
              _EmptyState(title: labels.emptyTitle, body: labels.emptyBody),
            for (final item in items) ...[
              NotificationTile(
                key: ValueKey('notification-${item.id}'),
                notification: item,
                timestamp: labels.timestamp(item.createdAt),
                unreadLabel: labels.unread,
                markReadLabel: labels.markRead,
                onTap: () => _open(context, ref, item),
                onMarkRead: () =>
                    _mark(context, () => _controller(ref).markRead(item.id)),
              ),
              const SizedBox(height: TelmizoSpacing.sm),
            ],
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(TelmizoSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (state.loadMoreFailed)
              Center(
                child: TextButton.icon(
                  onPressed: () => _controller(ref).loadMore(),
                  icon: const Icon(Icons.refresh),
                  label: Text(labels.loadMoreFailed),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TelmizoSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: TelmizoColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 44,
              color: TelmizoColors.primary,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          Text(
            title,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
