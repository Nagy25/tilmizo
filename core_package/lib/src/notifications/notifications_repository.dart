import 'package:flutter/foundation.dart';

import 'app_notification.dart';

/// The `p_app` value of `register_notification_device`.
enum NotificationApp {
  teacher('teacher'),
  student('student');

  const NotificationApp(this.value);

  final String value;
}

/// The `p_platform` value of `register_notification_device`.
enum NotificationPlatform {
  android('android'),
  ios('ios'),
  web('web');

  const NotificationPlatform(this.value);

  final String value;
}

@immutable
final class NotificationsPage {
  const NotificationsPage({required this.notifications, required this.hasMore});

  final List<AppNotification> notifications;
  final bool hasMore;
}

/// The signed-in user's notification center and push devices.
///
/// Reads go through `user_notifications` RLS; writes go through the
/// authenticated RPCs. Every method throws only `AppFailure`.
abstract interface class NotificationsRepository {
  /// Newest first.
  Future<NotificationsPage> fetchNotifications({
    int offset = 0,
    int limit = 20,
  });

  Future<int> fetchUnreadCount();

  /// Returns the stored read time.
  Future<DateTime> markRead(String notificationId);

  /// Returns how many notifications were marked.
  Future<int> markAllRead();

  /// Registers this installation's FCM [token]. Throws
  /// `AppFailureType.notEligible` while the account has no group (teacher)
  /// or membership (student), and `AppFailureType.rejected` when the token
  /// is still registered to another account.
  Future<void> registerDevice({
    required String token,
    required NotificationPlatform platform,
    required NotificationApp app,
  });

  Future<void> revokeDevice(String token);
}
