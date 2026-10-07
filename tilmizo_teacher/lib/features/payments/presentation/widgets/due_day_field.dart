import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/payment_models.dart';

/// The monthly plan's due day, chosen from a 1–31 day grid. Days beyond a
/// shorter month's end are clamped by the backend to its last day.
class DueDayField extends StatelessWidget {
  const DueDayField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DueDaySheet(selected: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.textTheme.bodySmall?.copyWith(
      color: TelmizoColors.onSurfaceVariant,
    );
    return TelmizoFormField(
      label: LocaleKeys.payments_due_day_label.tr(),
      isRequired: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: TelmizoColors.surfaceContainerLowest,
            shape: const RoundedRectangleBorder(
              borderRadius: TelmizoRadius.lgAll,
              side: BorderSide(color: TelmizoColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              key: const Key('due-day-field'),
              enabled: enabled,
              onTap: () => _pick(context),
              leading: CircleAvatar(
                backgroundColor: TelmizoColors.primaryTint,
                foregroundColor: TelmizoColors.primary,
                child: Text(
                  '$value',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: TelmizoColors.primary,
                  ),
                ),
              ),
              title: Text(
                LocaleKeys.payments_due_day_value.tr(args: ['$value']),
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
            ),
          ),
          if (value > 28) ...[
            const SizedBox(height: TelmizoSpacing.xs),
            Text(
              LocaleKeys.payments_due_day_clamp_note.tr(),
              key: const Key('due-day-clamp-note'),
              style: muted,
            ),
          ],
          const SizedBox(height: TelmizoSpacing.xs),
          Text(LocaleKeys.payments_due_day_join_note.tr(), style: muted),
        ],
      ),
    );
  }
}

class _DueDaySheet extends StatelessWidget {
  const _DueDaySheet({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        TelmizoSpacing.margin,
        0,
        TelmizoSpacing.margin,
        TelmizoSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.payments_due_day_sheet_title.tr(),
            style: context.textTheme.headlineSmall,
          ),
          const SizedBox(height: TelmizoSpacing.xs),
          Text(
            LocaleKeys.payments_due_day_sheet_subtitle.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: TelmizoSpacing.xs,
            crossAxisSpacing: TelmizoSpacing.xs,
            children: [
              for (
                var day = MonthlyPaymentPlan.minDueDay;
                day <= MonthlyPaymentPlan.maxDueDay;
                day++
              )
                _DayCell(day: day, selected: day == selected),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.md),
          TelmizoInlineMessage(
            message: LocaleKeys.payments_due_day_clamp_note.tr(),
            tone: TelmizoMessageTone.info,
          ),
        ],
      ),
    ),
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected});

  final int day;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected
          ? TelmizoColors.primary
          : TelmizoColors.surfaceContainerLow,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('due-day-$day'),
        onTap: () => Navigator.of(context).pop(day),
        child: Center(
          child: Text(
            '$day',
            style: context.textTheme.titleSmall?.copyWith(
              color: selected
                  ? TelmizoColors.onPrimary
                  : TelmizoColors.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}
