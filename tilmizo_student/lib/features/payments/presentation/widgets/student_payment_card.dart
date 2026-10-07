import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../payment_labels.dart';

/// One read-only record: source, title, amount and date, plus the paid
/// timestamp and method when paid. There is no pay action.
class StudentPaymentCard extends StatelessWidget {
  const StudentPaymentCard({
    super.key,
    required this.obligation,
    this.groupName,
  });

  final PaymentObligation obligation;

  /// Shown in the cross-group history.
  final String? groupName;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final receipt = obligation.receipt;
    final muted = textTheme.bodySmall?.copyWith(
      color: TelmizoColors.onSurfaceVariant,
    );
    return TelmizoCard(
      key: Key('student-payment-${obligation.id}'),
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: TelmizoColors.primaryTint,
                foregroundColor: TelmizoColors.primary,
                child: Icon(obligation.sourceType.icon),
              ),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.paymentTitle(obligation),
                      style: textTheme.titleSmall,
                    ),
                    if (groupName case final name?) Text(name, style: muted),
                    if (obligation.description case final description?)
                      Text(description, style: muted),
                  ],
                ),
              ),
              const SizedBox(width: TelmizoSpacing.sm),
              Text(
                egpLabel(obligation.amount),
                style: textTheme.titleMedium?.copyWith(
                  color: obligation.isPaid
                      ? TelmizoColors.success
                      : TelmizoColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Wrap(
            spacing: TelmizoSpacing.xs,
            runSpacing: TelmizoSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TelmizoPill(
                label: obligation.sourceType.label,
                background: TelmizoColors.surfaceContainerLow,
                foreground: TelmizoColors.onSurfaceVariant,
              ),
              if (obligation.isPaid)
                TelmizoPill(
                  label: LocaleKeys.payments_status_paid.tr(),
                  icon: Icons.check_circle,
                  background: TelmizoColors.successContainer,
                  foreground: TelmizoColors.success,
                )
              else
                TelmizoPill(
                  label: LocaleKeys.payments_status_unpaid.tr(),
                  background: TelmizoColors.tertiaryContainer,
                  foreground: TelmizoColors.onTertiaryContainer,
                ),
              Text(
                LocaleKeys.payments_record_date.tr(
                  args: [context.paymentDate(obligation.dueOn)],
                ),
                style: muted,
              ),
            ],
          ),
          if (receipt != null) ...[
            const SizedBox(height: TelmizoSpacing.xs),
            Text(context.paidAt(receipt), style: muted),
          ],
        ],
      ),
    );
  }
}
