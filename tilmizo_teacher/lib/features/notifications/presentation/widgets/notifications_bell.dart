import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/app_router.dart';
import '../notification_labels.dart';

/// Home-header bell with the unread count; opens the notification center.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider).value;
    return NotificationBellButton(
      key: const Key('notifications-bell'),
      unreadCount: unread,
      semanticLabel: notificationBellLabel(unread),
      onPressed: () => context.router.push(const NotificationsRoute()),
    );
  }
}
