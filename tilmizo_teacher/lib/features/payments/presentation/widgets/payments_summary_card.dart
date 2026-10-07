import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../payment_labels.dart';

/// Expected, paid and unpaid totals of current (non-void) records.
class PaymentsSummaryCard extends StatelessWidget {
  const PaymentsSummaryCard({super.key, required this.totals});

  final PaymentTotals totals;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoCard(
      key: const Key('payments-summary'),
      color: TelmizoColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.payments_summary_expected.tr(),
            style: textTheme.labelLarge?.copyWith(
              color: TelmizoColors.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: TelmizoSpacing.xs),
          Text(
            egpLabel(totals.expected),
            style: textTheme.headlineMedium?.copyWith(
              color: TelmizoColors.onPrimary,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: LocaleKeys.payments_summary_paid.tr(),
                  amount: totals.paid,
                  count: totals.paidCount,
                ),
              ),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: _Figure(
                  label: LocaleKeys.payments_summary_unpaid.tr(),
                  amount: totals.unpaid,
                  count: totals.unpaidCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.amount,
    required this.count,
  });

  final String label;
  final EgpAmount amount;
  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    const muted = Color(0xD9FFFFFF);
    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.sm),
      decoration: BoxDecoration(
        color: TelmizoColors.onPrimary.withValues(alpha: 0.12),
        borderRadius: TelmizoRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelMedium?.copyWith(color: muted)),
          Text(
            egpLabel(amount),
            style: textTheme.titleMedium?.copyWith(
              color: TelmizoColors.onPrimary,
            ),
          ),
          Text(
            LocaleKeys.payments_records_count.plural(count),
            style: textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
