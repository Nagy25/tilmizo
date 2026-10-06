import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/schedule_entry.dart';
import '../formatting/session_formatting.dart';
import 'class_pickers.dart';
import 'session_location_fields.dart';

/// Editable values of one weekday in the weekly schedule form.
class WeeklyDayDraft {
  WeeklyDayDraft(this.weekday, {WeeklySlot? from})
    : start = from?.start,
      end = from?.end,
      type = from?.location.type ?? SessionLocationType.physical,
      place = TextEditingController(text: from?.location.physicalLocation),
      link = TextEditingController(text: from?.location.meetingLink);

  final int weekday;
  ClockTime? start;
  ClockTime? end;
  SessionLocationType type;
  final TextEditingController place;
  final TextEditingController link;

  /// The slot, or null while any value is missing or invalid.
  WeeklySlot? toSlot() {
    final start = this.start;
    final end = this.end;
    final location = SessionLocationFields.read(type, place, link);
    if (start == null || end == null || location == null) return null;
    if (!start.isBefore(end)) return null;
    return WeeklySlot(
      weekday: weekday,
      start: start,
      end: end,
      location: location,
    );
  }

  void dispose() {
    place.dispose();
    link.dispose();
  }
}

/// Times and location for one weekday of a weekly schedule.
class WeeklyDayCard extends StatelessWidget {
  const WeeklyDayCard({
    super.key,
    required this.draft,
    required this.onChanged,
    this.onRemove,
    this.enabled = true,
  });

  final WeeklyDayDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoCard(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: TelmizoColors.primaryTint,
                foregroundColor: TelmizoColors.primary,
                child: Icon(Icons.today_outlined),
              ),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: Text(
                  LocaleKeys.schedule_day_card_title.tr(
                    args: [context.weekdayName(draft.weekday)],
                  ),
                  style: textTheme.titleMedium,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: enabled ? onRemove : null,
                  tooltip: LocaleKeys.schedule_remove_day.tr(),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: TelmizoColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.md),
          ClockRangeFields(
            start: draft.start,
            end: draft.end,
            enabled: enabled,
            onStartChanged: (time) {
              draft.start = time;
              onChanged();
            },
            onEndChanged: (time) {
              draft.end = time;
              onChanged();
            },
          ),
          const SizedBox(height: TelmizoSpacing.md),
          SessionLocationFields(
            type: draft.type,
            enabled: enabled,
            placeController: draft.place,
            linkController: draft.link,
            onTypeChanged: (type) {
              draft.type = type;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}
