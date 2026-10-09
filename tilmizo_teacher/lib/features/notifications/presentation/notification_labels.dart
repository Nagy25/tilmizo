import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../generated/locale_keys.g.dart';

/// Header bell label including the unread count.
String notificationBellLabel(int? unread) =>
    LocaleKeys.notifications_bell_semantics.plural(unread ?? 0);

NotificationPermissionLabels notificationPermissionLabels() =>
    NotificationPermissionLabels(
      disabledTitle: LocaleKeys.notifications_permission_disabled_title.tr(),
      disabledBody: LocaleKeys.notifications_permission_disabled_body.tr(),
      blockedBody: LocaleKeys.notifications_permission_blocked_body.tr(),
      enableAction: LocaleKeys.notifications_permission_enable.tr(),
      openSettingsAction: LocaleKeys.notifications_permission_open_settings
          .tr(),
      manualSteps: LocaleKeys.notifications_permission_manual.tr(),
      enabledTitle: LocaleKeys.notifications_permission_enabled_title.tr(),
      enabledBody: LocaleKeys.notifications_permission_enabled_body.tr(),
    );

NotificationCenterLabels notificationCenterLabels(
  BuildContext context,
  DateTime now,
) => NotificationCenterLabels(
  emptyTitle: LocaleKeys.notifications_empty_title.tr(),
  emptyBody: LocaleKeys.notifications_empty_body.tr(),
  errorTitle: LocaleKeys.notifications_load_error_title.tr(),
  retry: LocaleKeys.common_retry.tr(),
  markAllRead: LocaleKeys.notifications_mark_all_read.tr(),
  markRead: LocaleKeys.notifications_mark_read.tr(),
  markReadFailed: LocaleKeys.notifications_mark_read_failed.tr(),
  unread: LocaleKeys.notifications_unread.tr(),
  loadMoreFailed: LocaleKeys.notifications_load_more_error.tr(),
  errorMessage: (error) => appFailureMessage(failureTypeOf(error)),
  timestamp: (createdAt) =>
      notificationTime(createdAt, now, context.locale.toLanguageTag()),
  permission: notificationPermissionLabels(),
);

/// Relative within the last day, otherwise a Cairo date and time.
String notificationTime(DateTime createdAt, DateTime now, String locale) {
  final elapsed = now.difference(createdAt);
  if (elapsed.inMinutes < 1) return LocaleKeys.notifications_time_now.tr();
  if (elapsed.inHours < 1) {
    return LocaleKeys.notifications_time_minutes.plural(elapsed.inMinutes);
  }
  final created = CairoTime.toCairo(createdAt);
  final today = CairoTime.toCairo(now);
  final days = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(created.year, created.month, created.day)).inDays;
  final time = DateFormat.jm(locale).format(created);
  return switch (days) {
    <= 0 => LocaleKeys.notifications_time_hours.plural(elapsed.inHours),
    1 => LocaleKeys.notifications_time_yesterday.tr(args: [time]),
    _ => '${DateFormat.yMMMd(locale).format(created)} $time',
  };
}
