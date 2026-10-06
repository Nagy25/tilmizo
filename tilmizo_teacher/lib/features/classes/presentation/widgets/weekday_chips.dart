import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../formatting/session_formatting.dart';

/// Saturday-first weekday toggles for the weekly schedule form.
class WeekdayChips extends StatelessWidget {
  const WeekdayChips({
    super.key,
    required this.selected,
    required this.onToggled,
    this.enabled = true,
    this.errorText,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggled;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final errorText = this.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TelmizoFieldLabel(
          label: LocaleKeys.schedule_days_label.tr(),
          isRequired: true,
          trailing: Text(
            LocaleKeys.schedule_days_selected.tr(args: ['${selected.length}']),
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ),
        Wrap(
          spacing: TelmizoSpacing.sm,
          runSpacing: TelmizoSpacing.sm,
          children: [
            for (final weekday in weekdayDisplayOrder)
              FilterChip(
                key: Key('weekday-$weekday'),
                label: Text(context.weekdayName(weekday)),
                selected: selected.contains(weekday),
                onSelected: enabled ? (_) => onToggled(weekday) : null,
              ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            errorText,
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
