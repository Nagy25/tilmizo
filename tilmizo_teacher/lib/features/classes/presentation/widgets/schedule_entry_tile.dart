import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/schedule_entry.dart';
import '../formatting/session_formatting.dart';
import 'session_location_line.dart';

/// One active weekly slot with edit and stop actions.
class ScheduleEntryTile extends StatelessWidget {
  const ScheduleEntryTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDeactivate,
    this.enabled = true,
  });

  final ScheduleEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final slot = entry.slot;
    return TelmizoCard(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.weekdayName(slot.weekday),
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      context.slotTimeRange(slot),
                      style: textTheme.titleSmall?.copyWith(
                        color: TelmizoColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: Key('edit-entry-${entry.id}'),
                onPressed: enabled ? onEdit : null,
                child: Text(LocaleKeys.schedule_edit.tr()),
              ),
              TextButton(
                key: Key('deactivate-entry-${entry.id}'),
                style: TextButton.styleFrom(
                  foregroundColor: TelmizoColors.error,
                ),
                onPressed: enabled ? onDeactivate : null,
                child: Text(LocaleKeys.schedule_deactivate.tr()),
              ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          SessionLocationLine(location: slot.location),
        ],
      ),
    );
  }
}

Future<bool> confirmScheduleDeactivation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.event_busy_outlined, color: TelmizoColors.error),
      title: Text(LocaleKeys.schedule_deactivate_title.tr()),
      content: Text(LocaleKeys.schedule_deactivate_body.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(LocaleKeys.common_cancel.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(LocaleKeys.schedule_deactivate_confirm.tr()),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
