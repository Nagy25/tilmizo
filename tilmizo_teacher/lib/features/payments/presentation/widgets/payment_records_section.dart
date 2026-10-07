import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/payment_models.dart';
import 'payment_record_card.dart';
import 'payments_message_card.dart';

/// The Unpaid/Paid filter and the matching records.
class PaymentRecordsSection extends StatefulWidget {
  const PaymentRecordsSection({
    super.key,
    required this.records,
    required this.busyRecordId,
    this.onMarkPaid,
    this.onVoidPaid,
  });

  final List<StudentPaymentRecord> records;
  final String? busyRecordId;
  final void Function(StudentPaymentRecord record)? onMarkPaid;
  final void Function(StudentPaymentRecord record)? onVoidPaid;

  @override
  State<PaymentRecordsSection> createState() => _PaymentRecordsSectionState();
}

class _PaymentRecordsSectionState extends State<PaymentRecordsSection> {
  var _showPaid = false;

  @override
  Widget build(BuildContext context) {
    final unpaid = [
      for (final record in widget.records)
        if (record.obligation.isUnpaid) record,
    ];
    final paid = [
      for (final record in widget.records)
        if (record.obligation.isPaid) record,
    ];
    final visible = _showPaid ? paid : unpaid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          key: const Key('payments-filter'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: false,
              label: Text(
                LocaleKeys.payments_filter_unpaid.tr(
                  args: ['${unpaid.length}'],
                ),
                key: const Key('payments-filter-unpaid'),
              ),
            ),
            ButtonSegment(
              value: true,
              label: Text(
                LocaleKeys.payments_filter_paid.tr(args: ['${paid.length}']),
                key: const Key('payments-filter-paid'),
              ),
            ),
          ],
          selected: {_showPaid},
          onSelectionChanged: (selection) =>
              setState(() => _showPaid = selection.single),
        ),
        const SizedBox(height: TelmizoSpacing.md),
        if (visible.isEmpty)
          PaymentsMessageCard(
            icon: _showPaid ? Icons.receipt_outlined : Icons.task_alt,
            title: _showPaid
                ? LocaleKeys.payments_empty_paid.tr()
                : LocaleKeys.payments_empty_unpaid.tr(),
          )
        else
          for (final record in visible) ...[
            PaymentRecordCard(
              record: record,
              isBusy: widget.busyRecordId == record.obligation.id,
              onMarkPaid: widget.onMarkPaid == null
                  ? null
                  : () => widget.onMarkPaid!(record),
              onVoidPaid: widget.onVoidPaid == null
                  ? null
                  : () => widget.onVoidPaid!(record),
            ),
            const SizedBox(height: TelmizoSpacing.sm),
          ],
      ],
    );
  }
}
