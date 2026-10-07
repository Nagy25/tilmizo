import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/payment_models.dart';
import '../payment_labels.dart';

/// One student's record: student, source, title, amount and date, plus the
/// paid timestamp and method when paid. Actions are null when read-only.
class PaymentRecordCard extends StatelessWidget {
  const PaymentRecordCard({
    super.key,
    required this.record,
    this.onMarkPaid,
    this.onVoidPaid,
    this.isBusy = false,
  });

  final StudentPaymentRecord record;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onVoidPaid;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final obligation = record.obligation;
    final receipt = obligation.receipt;
    final muted = textTheme.bodySmall?.copyWith(
      color: TelmizoColors.onSurfaceVariant,
    );
    return TelmizoCard(
      key: Key('payment-record-${obligation.id}'),
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TelmizoAvatar(fullName: record.studentName, size: 40),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.studentName ??
                          LocaleKeys.payments_unknown_student.tr(),
                      style: textTheme.titleSmall,
                    ),
                    Text(context.paymentTitle(obligation), style: muted),
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
                icon: obligation.sourceType.icon,
                background: TelmizoColors.surfaceContainerLow,
                foreground: TelmizoColors.onSurfaceVariant,
              ),
              _StatusPill(isPaid: obligation.isPaid),
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
            Row(
              children: [
                Icon(
                  receipt.method.icon,
                  size: 16,
                  color: TelmizoColors.success,
                ),
                const SizedBox(width: TelmizoSpacing.xs),
                Expanded(child: Text(context.paidAt(receipt), style: muted)),
              ],
            ),
          ],
          if (obligation.isUnpaid && onMarkPaid != null) ...[
            const SizedBox(height: TelmizoSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonalIcon(
                key: Key('mark-paid-${obligation.id}'),
                onPressed: isBusy ? null : onMarkPaid,
                icon: _icon(Icons.check_circle_outline),
                label: Text(LocaleKeys.payments_mark_paid.tr()),
              ),
            ),
          ],
          if (obligation.isPaid && receipt != null && onVoidPaid != null) ...[
            const SizedBox(height: TelmizoSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: Key('void-paid-${obligation.id}'),
                onPressed: isBusy ? null : onVoidPaid,
                style: TextButton.styleFrom(
                  foregroundColor: TelmizoColors.error,
                ),
                icon: _icon(Icons.undo),
                label: Text(LocaleKeys.payments_void_paid.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _icon(IconData icon) => isBusy
      ? const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(icon);
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isPaid});

  final bool isPaid;

  @override
  Widget build(BuildContext context) => isPaid
      ? TelmizoPill(
          label: LocaleKeys.payments_status_paid.tr(),
          icon: Icons.check_circle,
          background: TelmizoColors.successContainer,
          foreground: TelmizoColors.success,
        )
      : TelmizoPill(
          label: LocaleKeys.payments_status_unpaid.tr(),
          icon: Icons.schedule,
          background: TelmizoColors.tertiaryContainer,
          foreground: TelmizoColors.onTertiaryContainer,
        );
}
