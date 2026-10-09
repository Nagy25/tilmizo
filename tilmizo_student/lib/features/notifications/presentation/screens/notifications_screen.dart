import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../notification_labels.dart';
import '../notification_navigation.dart';

/// The student notification center: homework, announcements, resources,
/// classes, and payments from the student's groups.
@RoutePage()
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = context.router;
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.notifications_title.tr(),
        subtitle: LocaleKeys.notifications_subtitle.tr(),
        showBack: true,
      ),
      body: NotificationCenterView(
        labels: notificationCenterLabels(context, ref.read(clockProvider)()),
        onOpen: (notification) => openNotificationTarget(
          ref,
          router,
          notification.target,
          context: context,
        ),
      ),
    );
  }
}
