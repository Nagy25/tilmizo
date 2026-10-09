import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_failure.dart';
import '../providers/clock_provider.dart';
import 'app_notification.dart';
import 'notifications_repository.dart';
import 'notifications_repository_impl.dart';

/// Unread notifications for the header badge.
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificationsRepositoryProvider).fetchUnreadCount(),
);

@immutable
final class NotificationCenterState {
  const NotificationCenterState({
    required this.notifications,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<AppNotification> notifications;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasUnread => notifications.any((item) => !item.isRead);

  NotificationCenterState copyWith({
    List<AppNotification>? notifications,
    bool? hasMore,
    bool isLoadingMore = false,
    bool loadMoreFailed = false,
  }) => NotificationCenterState(
    notifications: notifications ?? this.notifications,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore,
    loadMoreFailed: loadMoreFailed,
  );
}

/// The notification center, newest first and paged by offset. Disposed with
/// its screen, so every opening loads fresh rows.
final notificationCenterProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationCenterController,
      NotificationCenterState
    >(NotificationCenterController.new);

class NotificationCenterController
    extends AsyncNotifier<NotificationCenterState> {
  static const pageSize = 20;

  NotificationsRepository get _repository =>
      ref.read(notificationsRepositoryProvider);

  @override
  Future<NotificationCenterState> build() async {
    final page = await ref
        .watch(notificationsRepositoryProvider)
        .fetchNotifications(limit: pageSize);
    return NotificationCenterState(
      notifications: page.notifications,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    ref.invalidate(unreadNotificationCountProvider);
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.fetchNotifications(
        offset: current.notifications.length,
        limit: pageSize,
      );
      if (!ref.mounted) return;
      // Rows that arrived meanwhile shift offsets; drop the repeats.
      final known = {for (final item in current.notifications) item.id};
      state = AsyncData(
        current.copyWith(
          notifications: [
            ...current.notifications,
            ...page.notifications.where((item) => !known.contains(item.id)),
          ],
          hasMore: page.hasMore,
        ),
      );
    } on AppFailure {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(loadMoreFailed: true));
    }
  }

  /// Marks one notification read, optimistically. Throws [AppFailure] after
  /// restoring the previous state.
  Future<void> markRead(String notificationId) async {
    final current = state.value;
    final item = current?.notifications
        .where((n) => n.id == notificationId)
        .firstOrNull;
    if (current == null || item == null || item.isRead) return;
    _replace(current, (n) => n.id == notificationId, ref.read(clockProvider)());
    try {
      final readAt = await _repository.markRead(notificationId);
      if (!ref.mounted) return;
      final latest = state.value;
      if (latest != null) {
        _replace(latest, (n) => n.id == notificationId, readAt);
      }
    } on AppFailure {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    } finally {
      ref.invalidate(unreadNotificationCountProvider);
    }
  }

  /// Marks every notification read, optimistically. Throws [AppFailure]
  /// after restoring the previous state.
  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null) return;
    _replace(current, (n) => !n.isRead, ref.read(clockProvider)());
    try {
      await _repository.markAllRead();
    } on AppFailure {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    } finally {
      ref.invalidate(unreadNotificationCountProvider);
    }
  }

  void _replace(
    NotificationCenterState from,
    bool Function(AppNotification) test,
    DateTime readAt,
  ) {
    state = AsyncData(
      from.copyWith(
        notifications: [
          for (final n in from.notifications)
            test(n) ? n.markedRead(readAt) : n,
        ],
        isLoadingMore: from.isLoadingMore,
        loadMoreFailed: from.loadMoreFailed,
      ),
    );
  }
}

/// A notification tap waiting until the app has finished startup and can
/// navigate.
final pendingNotificationOpenProvider =
    NotifierProvider<PendingNotificationOpen, NotificationTarget?>(
      PendingNotificationOpen.new,
    );

class PendingNotificationOpen extends Notifier<NotificationTarget?> {
  @override
  NotificationTarget? build() => null;

  void set(NotificationTarget target) => state = target;

  /// Returns and clears the pending tap.
  NotificationTarget? take() {
    final target = state;
    state = null;
    return target;
  }
}

extension NotificationRefresh on WidgetRef {
  /// Reloads the badge, and the center when it is open.
  void refreshNotifications() {
    invalidate(unreadNotificationCountProvider);
    if (exists(notificationCenterProvider)) {
      invalidate(notificationCenterProvider);
    }
  }
}
