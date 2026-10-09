import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../notification_navigation.dart';

/// Student wiring for [PushNotificationsHost]: home is the groups home or
/// the empty-groups screen at the base of the stack.
class AppNotificationsHost extends ConsumerWidget {
  const AppNotificationsHost({
    super.key,
    required this.router,
    required this.child,
  });

  static final _homeRoutes = {GroupsHomeRoute.name, EmptyGroupsRoute.name};

  final AppRouter router;
  final Widget child;

  void _showForeground(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.notifications_foreground_new.tr()),
          action: SnackBarAction(
            label: LocaleKeys.notifications_foreground_view.tr(),
            onPressed: () => router.push(const NotificationsRoute()),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => PushNotificationsHost(
    readiness: router,
    isAtHome: () => _homeRoutes.contains(router.stackData.firstOrNull?.name),
    openTarget: (target) => openNotificationTarget(ref, router, target),
    onForegroundMessage: (_) => _showForeground(context),
    child: child,
  );
}
