import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../controllers/student_payments_providers.dart';
import '../payment_labels.dart';
import 'student_payment_card.dart';

/// The student's own records divided into Unpaid and Paid, for one group or
/// (with a null [groupId]) every group. Shared by the group tab and the
/// account history screen.
class StudentPaymentsView extends ConsumerStatefulWidget {
  const StudentPaymentsView({
    super.key,
    required this.groupId,
    required this.onRefresh,
    this.intro,
    this.groupNames = const {},
  });

  final String? groupId;
  final Future<void> Function() onRefresh;
  final String? intro;

  /// Group names for the cross-group history; unknown groups get a generic
  /// label because a left group may no longer be readable.
  final Map<String, String> groupNames;

  @override
  ConsumerState<StudentPaymentsView> createState() =>
      _StudentPaymentsViewState();
}

class _StudentPaymentsViewState extends ConsumerState<StudentPaymentsView> {
  var _showPaid = false;

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(studentPaymentsProvider(widget.groupId));
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          TelmizoSpacing.lg,
          TelmizoSpacing.margin,
          TelmizoSpacing.xl,
        ),
        children: [
          TelmizoInlineMessage(
            message: widget.intro ?? LocaleKeys.payments_intro.tr(),
            tone: TelmizoMessageTone.info,
          ),
          const SizedBox(height: TelmizoSpacing.md),
          ...switch (payments) {
            AsyncData(:final value) when value.isEmpty => [
              _Message(
                key: const Key('student-payments-empty'),
                icon: Icons.account_balance_wallet_outlined,
                title: LocaleKeys.payments_empty_title.tr(),
                body: LocaleKeys.payments_empty_body.tr(),
              ),
            ],
            AsyncData(:final value) => _records(value),
            AsyncError(:final error) => [
              _Message(
                key: const Key('student-payments-error'),
                icon: Icons.cloud_off_outlined,
                title: LocaleKeys.payments_load_error_title.tr(),
                body: appFailureMessage(failureTypeOf(error)),
                actionLabel: LocaleKeys.common_retry.tr(),
                onAction: () => refreshStudentPayments(ref, widget.groupId),
              ),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(TelmizoSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }

  List<Widget> _records(List<PaymentObligation> obligations) {
    final totals = PaymentTotals.of(obligations);
    final visible = [
      for (final obligation in obligations)
        if (obligation.isPaid == _showPaid) obligation,
    ];
    return [
      Row(
        children: [
          Expanded(
            child: _Total(
              key: const Key('student-payments-unpaid-total'),
              label: LocaleKeys.payments_summary_unpaid.tr(),
              amount: totals.unpaid,
              color: TelmizoColors.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: TelmizoSpacing.md),
          Expanded(
            child: _Total(
              label: LocaleKeys.payments_summary_paid.tr(),
              amount: totals.paid,
              color: TelmizoColors.success,
            ),
          ),
        ],
      ),
      const SizedBox(height: TelmizoSpacing.md),
      SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: false,
            label: Text(
              LocaleKeys.payments_filter_unpaid.tr(
                args: ['${totals.unpaidCount}'],
              ),
              key: const Key('student-payments-unpaid'),
            ),
          ),
          ButtonSegment(
            value: true,
            label: Text(
              LocaleKeys.payments_filter_paid.tr(args: ['${totals.paidCount}']),
              key: const Key('student-payments-paid'),
            ),
          ),
        ],
        selected: {_showPaid},
        onSelectionChanged: (selection) =>
            setState(() => _showPaid = selection.single),
      ),
      const SizedBox(height: TelmizoSpacing.md),
      if (visible.isEmpty)
        _Message(
          icon: _showPaid ? Icons.receipt_outlined : Icons.task_alt,
          title: _showPaid
              ? LocaleKeys.payments_empty_paid.tr()
              : LocaleKeys.payments_empty_unpaid.tr(),
        )
      else
        for (final obligation in visible) ...[
          StudentPaymentCard(
            obligation: obligation,
            groupName: widget.groupId == null
                ? widget.groupNames[obligation.groupId] ??
                      LocaleKeys.payments_previous_group.tr()
                : null,
          ),
          const SizedBox(height: TelmizoSpacing.sm),
        ],
    ];
  }
}

class _Total extends StatelessWidget {
  const _Total({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final EgpAmount amount;
  final Color color;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    padding: const EdgeInsets.all(TelmizoSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textTheme.labelLarge),
        const SizedBox(height: TelmizoSpacing.xs),
        Text(
          egpLabel(amount),
          style: context.textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Column(
      children: [
        Icon(icon, size: 40, color: TelmizoColors.onSurfaceVariant),
        const SizedBox(height: TelmizoSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium,
        ),
        if (body case final body?) ...[
          const SizedBox(height: TelmizoSpacing.xs),
          Text(body, textAlign: TextAlign.center),
        ],
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}
