import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/payment_models.dart';
import '../payment_labels.dart';

/// Confirms a full payment of [record] and returns the chosen method. There
/// is no amount input: only the full expected amount can be recorded.
Future<PaymentMethod?> showMarkPaidSheet(
  BuildContext context,
  StudentPaymentRecord record,
) => showModalBottomSheet<PaymentMethod>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _MarkPaidSheet(record: record),
);

class _MarkPaidSheet extends StatefulWidget {
  const _MarkPaidSheet({required this.record});

  final StudentPaymentRecord record;

  @override
  State<_MarkPaidSheet> createState() => _MarkPaidSheetState();
}

class _MarkPaidSheetState extends State<_MarkPaidSheet> {
  var _method = PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final obligation = widget.record.obligation;
    return SafeArea(
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
              LocaleKeys.payments_mark_paid_title.tr(),
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: TelmizoSpacing.xs),
            Text(
              LocaleKeys.payments_mark_paid_body.tr(
                args: [
                  widget.record.studentName ??
                      LocaleKeys.payments_unknown_student.tr(),
                  context.paymentTitle(obligation),
                ],
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            Text(
              egpLabel(obligation.amount),
              key: const Key('mark-paid-amount'),
              style: textTheme.headlineMedium?.copyWith(
                color: TelmizoColors.primary,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.md),
            Text(
              LocaleKeys.payments_method_label.tr(),
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            Wrap(
              spacing: TelmizoSpacing.sm,
              runSpacing: TelmizoSpacing.sm,
              children: [
                for (final method in PaymentMethod.values)
                  ChoiceChip(
                    key: Key('payment-method-${method.backendValue}'),
                    avatar: Icon(method.icon, size: 18),
                    label: Text(method.label),
                    selected: _method == method,
                    onSelected: (_) => setState(() => _method = method),
                  ),
              ],
            ),
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              message: LocaleKeys.payments_full_only_note.tr(),
              tone: TelmizoMessageTone.info,
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            TelmizoPrimaryButton(
              key: const Key('confirm-mark-paid'),
              label: LocaleKeys.payments_mark_paid_confirm.tr(),
              icon: Icons.check_circle_outline,
              onPressed: () => Navigator.of(context).pop(_method),
            ),
          ],
        ),
      ),
    );
  }
}
