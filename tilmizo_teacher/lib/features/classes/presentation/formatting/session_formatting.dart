import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/class_session.dart';
import '../../domain/schedule_entry.dart';
import '../../domain/session_location.dart';

/// Cairo-time display helpers for sessions and weekly slots.
extension SessionFormatting on BuildContext {
  String get _locale => locale.toLanguageTag();

  /// Full Cairo date, such as the weekday, day, month, and year.
  String cairoDate(DateTime instant) =>
      DateFormat.yMMMMEEEEd(_locale).format(CairoTime.toCairo(instant));

  String cairoShortDate(DateTime instant) =>
      DateFormat.MMMEd(_locale).format(CairoTime.toCairo(instant));

  String cairoTime(DateTime instant) =>
      DateFormat.jm(_locale).format(CairoTime.toCairo(instant));

  String sessionTimeRange(ClassSession session) =>
      '${cairoTime(session.startsAt)} – ${cairoTime(session.endsAt)}';

  /// A calendar date value (UTC midnight) without time-zone conversion.
  String calendarDate(DateTime date) =>
      DateFormat.yMMMMEEEEd(_locale).format(date);

  String clockTime(ClockTime time) =>
      DateFormat.jm(_locale)
          .format(DateTime.utc(2000, 1, 1, time.hour, time.minute));

  String slotTimeRange(WeeklySlot slot) =>
      '${clockTime(slot.start)} – ${clockTime(slot.end)}';

  /// The localized name of an ISO weekday (1 is Monday).
  String weekdayName(int isoWeekday) => DateFormat.EEEE(_locale)
      .format(DateTime.utc(2024, 1, isoWeekday)); // 2024-01-01 was a Monday.

  String durationLabel(Duration duration) =>
      LocaleKeys.minutes_count.plural(duration.inMinutes);

  /// "Today", "Tomorrow", or "In N days" for an upcoming Cairo date, or null
  /// for dates in the past.
  String? relativeDay(DateTime instant, DateTime now) {
    final days = CairoTime.calendarDaysBetween(now, instant);
    if (days < 0) return null;
    return switch (days) {
      0 => LocaleKeys.session_relative_today.tr(),
      1 => LocaleKeys.session_relative_tomorrow.tr(),
      _ => LocaleKeys.session_in_days.plural(days),
    };
  }
}

/// Saturday-first order used by Egyptian school weeks.
const weekdayDisplayOrder = [6, 7, 1, 2, 3, 4, 5];

String locationIssueMessage(SessionLocationIssue issue) => switch (issue) {
  SessionLocationIssue.missingPlace => LocaleKeys.location_missing_place,
  SessionLocationIssue.placeTooLong => LocaleKeys.location_place_too_long,
  SessionLocationIssue.missingLink => LocaleKeys.location_missing_link,
  SessionLocationIssue.invalidLink => LocaleKeys.location_invalid_link,
}.tr();

/// A user-safe message for a classes write or read failure.
String classesErrorMessage(Object? error) {
  if (error is ScheduleConflict) return LocaleKeys.schedule_conflict.tr();
  final type = failureTypeOf(error);
  if (type == AppFailureType.notFound) {
    return LocaleKeys.error_session_not_found.tr();
  }
  return appFailureMessage(type);
}
