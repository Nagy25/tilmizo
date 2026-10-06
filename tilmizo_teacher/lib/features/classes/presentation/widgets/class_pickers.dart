import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../formatting/session_formatting.dart';
import 'picker_form_field.dart';

Future<ClockTime?> pickClockTime(
  BuildContext context,
  ClockTime? current,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: current == null
        ? const TimeOfDay(hour: 17, minute: 0)
        : TimeOfDay(hour: current.hour, minute: current.minute),
  );
  return picked == null ? null : ClockTime(picked.hour, picked.minute);
}

/// Picks a Cairo calendar date, returned as a UTC midnight date value.
Future<DateTime?> pickCairoDate(
  BuildContext context, {
  required DateTime? current,
  required DateTime now,
}) async {
  final today = CairoTime.dateOf(now);
  final firstDate = DateTime(today.year, today.month, today.day);
  final initial = current ?? today;
  final initialDate = DateTime(initial.year, initial.month, initial.day);
  final lastDate = DateTime(today.year + 1, today.month, today.day);
  final picked = await showDatePicker(
    context: context,
    firstDate: initialDate.isBefore(firstDate) ? initialDate : firstDate,
    lastDate: initialDate.isAfter(lastDate) ? initialDate : lastDate,
    initialDate: initialDate,
  );
  return picked == null
      ? null
      : DateTime.utc(picked.year, picked.month, picked.day);
}

/// A start or end time field for Cairo wall-clock times.
class ClockTimeField extends StatelessWidget {
  const ClockTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.icon = Icons.schedule,
  });

  final String label;
  final ClockTime? value;
  final ValueChanged<ClockTime> onChanged;
  final FormFieldValidator<ClockTime>? validator;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) => PickerFormField<ClockTime>(
    label: label,
    initialValue: value,
    icon: icon,
    enabled: enabled,
    format: context.clockTime,
    pick: (current) => pickClockTime(context, current),
    onChanged: onChanged,
    validator:
        validator ??
        (time) => time == null ? LocaleKeys.schedule_time_required.tr() : null,
  );
}

/// Start and end time fields side by side, validating a same-day range.
class ClockRangeFields extends StatelessWidget {
  const ClockRangeFields({
    super.key,
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
    this.enabled = true,
  });

  final ClockTime? start;
  final ClockTime? end;
  final ValueChanged<ClockTime> onStartChanged;
  final ValueChanged<ClockTime> onEndChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final start = this.start;
    final end = this.end;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClockTimeField(
                label: LocaleKeys.schedule_start_label.tr(),
                value: start,
                icon: Icons.play_circle_outline,
                enabled: enabled,
                onChanged: onStartChanged,
              ),
            ),
            const SizedBox(width: TelmizoSpacing.md),
            Expanded(
              child: ClockTimeField(
                label: LocaleKeys.schedule_end_label.tr(),
                value: end,
                icon: Icons.stop_circle_outlined,
                enabled: enabled,
                onChanged: onEndChanged,
                validator: (value) {
                  if (value == null) {
                    return LocaleKeys.schedule_time_required.tr();
                  }
                  final from = this.start;
                  if (from != null && !from.isBefore(value)) {
                    return LocaleKeys.schedule_end_before_start.tr();
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        if (start != null && end != null && start.isBefore(end)) ...[
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            LocaleKeys.schedule_duration.tr(
              args: [
                context.durationLabel(
                  Duration(minutes: end.minutesOfDay - start.minutesOfDay),
                ),
              ],
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// A required Cairo calendar date field.
class CairoDateField extends StatelessWidget {
  const CairoDateField({
    super.key,
    required this.value,
    required this.now,
    required this.onChanged,
    this.enabled = true,
  });

  final DateTime? value;
  final DateTime now;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => PickerFormField<DateTime>(
    key: const Key('session-date-field'),
    label: LocaleKeys.session_date_label.tr(),
    initialValue: value,
    icon: Icons.calendar_month_outlined,
    enabled: enabled,
    format: context.calendarDate,
    pick: (current) => pickCairoDate(context, current: current, now: now),
    onChanged: onChanged,
    validator: (date) =>
        date == null ? LocaleKeys.session_date_required.tr() : null,
  );
}

/// Resolves a Cairo date and same-day time range to UTC instants, or null
/// when either time falls in a daylight-saving gap.
({DateTime startsAt, DateTime endsAt})? resolveCairoRange(
  DateTime date,
  ClockTime start,
  ClockTime end,
) {
  final startsAt = CairoTime.wallTimeToUtc(date, start.hour, start.minute);
  final endsAt = CairoTime.wallTimeToUtc(date, end.hour, end.minute);
  if (startsAt == null || endsAt == null || !endsAt.isAfter(startsAt)) {
    return null;
  }
  return (startsAt: startsAt, endsAt: endsAt);
}
