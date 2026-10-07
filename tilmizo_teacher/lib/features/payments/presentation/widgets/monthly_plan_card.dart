import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/payment_models.dart';
import '../payment_labels.dart';

/// The single active monthly plan with edit and stop actions. Actions are
/// null when the group is read-only or cannot start a new plan.
class MonthlyPlanCard extends StatelessWidget {
  const MonthlyPlanCard({
    super.key,
    required this.plan,
    this.onSetUp,
    this.onEdit,
    this.onStop,
    this.isStopping = false,
  });

  final MonthlyPaymentPlan? plan;
  final VoidCallback? onSetUp;
  final VoidCallback? onEdit;
  final VoidCallback? onStop;
  final bool isStopping;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final plan = this.plan;
    return TelmizoCard(
      key: const Key('monthly-plan-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: TelmizoColors.primaryTint,
                foregroundColor: TelmizoColors.primary,
                child: Icon(Icons.calendar_month_outlined),
              ),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.payments_monthly_card_title.tr(),
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      plan == null
                          ? LocaleKeys.payments_monthly_none.tr()
                          : LocaleKeys.payments_monthly_card_amount.tr(
                              args: [plan.amount.displayText],
                            ),
                      style: plan == null
                          ? textTheme.bodySmall?.copyWith(
                              color: TelmizoColors.onSurfaceVariant,
                            )
                          : textTheme.titleLarge?.copyWith(
                              color: TelmizoColors.primary,
                            ),
                    ),
                    if (plan != null)
                      Text(
                        plan.dueMode == MonthlyDueMode.joinDay
                            ? LocaleKeys.payments_monthly_card_join_due.tr()
                            : LocaleKeys.payments_monthly_card_due.tr(
                                args: ['${plan.dueDay}'],
                              ),
                        key: const Key('monthly-plan-due-day'),
                        style: textTheme.bodyMedium,
                      ),
                    if (plan != null)
                      Text(
                        LocaleKeys.payments_monthly_card_since.tr(
                          args: [context.paymentMonth(plan.startedMonth)],
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: TelmizoColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (plan == null && onSetUp != null) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoSecondaryButton(
              key: const Key('monthly-plan-set-up'),
              label: LocaleKeys.payments_monthly_setup.tr(),
              onPressed: onSetUp,
            ),
          ],
          if (plan != null && (onEdit != null || onStop != null)) ...[
            const SizedBox(height: TelmizoSpacing.sm),
            Text(
              LocaleKeys.payments_monthly_existing_note.tr(),
              style: textTheme.bodySmall?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            Wrap(
              spacing: TelmizoSpacing.sm,
              runSpacing: TelmizoSpacing.xs,
              children: [
                if (onEdit != null)
                  OutlinedButton.icon(
                    key: const Key('monthly-plan-edit'),
                    onPressed: isStopping ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(LocaleKeys.payments_monthly_edit.tr()),
                  ),
                if (onStop != null)
                  TextButton.icon(
                    key: const Key('monthly-plan-stop'),
                    onPressed: isStopping ? null : onStop,
                    style: TextButton.styleFrom(
                      foregroundColor: TelmizoColors.error,
                    ),
                    icon: isStopping
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.stop_circle_outlined),
                    label: Text(LocaleKeys.payments_monthly_stop.tr()),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
