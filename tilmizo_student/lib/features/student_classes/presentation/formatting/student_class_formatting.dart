import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/student_class.dart';

String sessionDate(BuildContext context, DateTime instant) =>
    MaterialLocalizations.of(context)
        .formatMediumDate(CairoTime.toCairo(instant));

String sessionClock(BuildContext context, DateTime instant) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(CairoTime.toCairo(instant)),
      alwaysUse24HourFormat: false,
    );

String sessionTimeRange(BuildContext context, DateTime start, DateTime end) =>
    '${sessionClock(context, start)} – ${sessionClock(context, end)}';

String scheduleTimeRange(BuildContext context, StudentScheduleEntry entry) {
  String clock(ClockTime value) =>
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay(hour: value.hour, minute: value.minute));
  return '${clock(entry.start)} – ${clock(entry.end)}';
}

String weekdayLabel(int weekday) => switch (weekday) {
  1 => LocaleKeys.weekday_monday.tr(),
  2 => LocaleKeys.weekday_tuesday.tr(),
  3 => LocaleKeys.weekday_wednesday.tr(),
  4 => LocaleKeys.weekday_thursday.tr(),
  5 => LocaleKeys.weekday_friday.tr(),
  6 => LocaleKeys.weekday_saturday.tr(),
  7 => LocaleKeys.weekday_sunday.tr(),
  _ => throw FormatException('Unknown ISO weekday', weekday),
};

String attendanceLabel(AttendanceStatus value) => switch (value) {
  AttendanceStatus.notMarked => LocaleKeys.attendance_not_marked.tr(),
  AttendanceStatus.present => LocaleKeys.attendance_present.tr(),
  AttendanceStatus.absent => LocaleKeys.attendance_absent.tr(),
  AttendanceStatus.late => LocaleKeys.attendance_late.tr(),
  AttendanceStatus.excused => LocaleKeys.attendance_excused.tr(),
};

String sessionStatusLabel(SessionStatus value) => switch (value) {
  SessionStatus.scheduled => LocaleKeys.session_scheduled.tr(),
  SessionStatus.completed => LocaleKeys.session_completed.tr(),
  SessionStatus.cancelled => LocaleKeys.session_cancelled.tr(),
};
