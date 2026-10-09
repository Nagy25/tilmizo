import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/locale_keys.g.dart';
import '../../../router/app_router.dart';
import '../../group_access/presentation/widgets/approved_group_tabs.dart';

/// The student screen for a target that RLS still shows in [groupId]. RLS
/// only returns group content to a student whose current session is
/// approved, so a removed or replaced student gets no route.
PageRouteInfo? notificationRoute(NotificationTarget target, String groupId) {
  final id = target.targetId;
  if (id == null) return null;
  return switch (target.eventType.targetKind) {
    NotificationTargetKind.homework => StudentHomeworkDetailsRoute(
      groupId: groupId,
      homeworkId: id,
    ),
    NotificationTargetKind.announcement => ApprovedGroupRoute(
      groupId: groupId,
      tab: ApprovedGroupTab.announcements.name,
    ),
    NotificationTargetKind.resource => ApprovedGroupRoute(
      groupId: groupId,
      tab: ApprovedGroupTab.resources.name,
    ),
    NotificationTargetKind.session => StudentSessionDetailsRoute(sessionId: id),
    NotificationTargetKind.payment => const PaymentHistoryRoute(),
    NotificationTargetKind.none => null,
  };
}

/// Opens a notification's destination after re-reading it. A push tap that
/// cannot be resolved opens the notification center instead; a tap inside
/// the center explains why via [context].
Future<void> openNotificationTarget(
  WidgetRef ref,
  StackRouter router,
  NotificationTarget target, {
  BuildContext? context,
}) async {
  final fromCenter = context != null;
  PageRouteInfo? route;
  try {
    final groupId = await ref
        .read(notificationTargetLookupProvider)
        .visibleGroupId(target);
    route = groupId == null ? null : notificationRoute(target, groupId);
  } on AppFailure {
    if (context != null && context.mounted) {
      showTelmizoSnackBar(context, LocaleKeys.notifications_open_failed.tr());
    } else if (!fromCenter) {
      unawaited(router.push(const NotificationsRoute()));
    }
    return;
  }
  if (route != null) {
    // Not awaited: a push completes only when the page is popped.
    unawaited(router.push(route));
  } else if (!fromCenter) {
    unawaited(router.push(const NotificationsRoute()));
  } else if (context.mounted) {
    showTelmizoSnackBar(
      context,
      LocaleKeys.notifications_target_unavailable.tr(),
    );
  }
}
