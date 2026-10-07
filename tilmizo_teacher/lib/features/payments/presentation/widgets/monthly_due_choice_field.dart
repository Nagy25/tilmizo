import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

enum MonthlyDueChoice { firstDay, specificDay, joinDay }

/// The three due-date choices in the monthly subscription design.
class MonthlyDueChoiceField extends StatelessWidget {
  const MonthlyDueChoiceField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final MonthlyDueChoice value;
  final ValueChanged<MonthlyDueChoice> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TelmizoFormField(
    label: LocaleKeys.payments_due_day_label.tr(),
    isRequired: true,
    child: Column(
      children: [
        _option(
          context,
          MonthlyDueChoice.firstDay,
          LocaleKeys.payments_due_choice_first.tr(),
          LocaleKeys.payments_due_choice_first_body.tr(),
          Icons.today_outlined,
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        _option(
          context,
          MonthlyDueChoice.specificDay,
          LocaleKeys.payments_due_choice_specific.tr(),
          LocaleKeys.payments_due_choice_specific_body.tr(),
          Icons.edit_calendar_outlined,
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        _option(
          context,
          MonthlyDueChoice.joinDay,
          LocaleKeys.payments_due_choice_join.tr(),
          LocaleKeys.payments_due_choice_join_body.tr(),
          Icons.person_add_alt_1_outlined,
        ),
      ],
    ),
  );

  Widget _option(
    BuildContext context,
    MonthlyDueChoice choice,
    String title,
    String body,
    IconData icon,
  ) {
    final selected = choice == value;
    return Material(
      color: selected
          ? TelmizoColors.primaryTint
          : TelmizoColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: TelmizoRadius.lgAll,
        side: BorderSide(
          color: selected ? TelmizoColors.primary : TelmizoColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('monthly-due-${choice.name}'),
        onTap: enabled ? () => onChanged(choice) : null,
        child: Padding(
          padding: const EdgeInsets.all(TelmizoSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: TelmizoColors.primary),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textTheme.titleSmall),
                    Text(
                      body,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: TelmizoColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? TelmizoColors.primary
                    : TelmizoColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
