import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../../domain/payment_models.dart';
import '../controllers/payments_providers.dart';
import 'mark_paid_sheet.dart';
import 'monthly_plan_card.dart';
import 'payment_dialogs.dart';
import 'payment_records_section.dart';
import 'payments_message_card.dart';
import 'payments_summary_card.dart';

/// The payments screen body: status notices, totals, the monthly plan and
/// the Unpaid/Paid records. Archived groups are history-only; suspended
/// groups can still mark or correct existing records.
class GroupPaymentsView extends ConsumerWidget {
  const GroupPaymentsView({
    super.key,
    required this.group,
    required this.onAdd,
  });

  final TeacherGroup group;
  final VoidCallback onAdd;

  PaymentActionsController _actions(WidgetRef ref) =>
      ref.read(paymentActionsControllerProvider.notifier);

  Future<void> _refresh(WidgetRef ref) {
    ref.invalidate(groupDetailsProvider(group.id));
    return ref.refresh(groupPaymentsProvider(group.id).future);
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    StudentPaymentRecord record,
  ) async {
    final method = await showMarkPaidSheet(context, record);
    if (method == null || !context.mounted) return;
    final ok = await _actions(ref).markPaid(record.obligation, method);
    if (context.mounted) {
      _report(context, ref, ok, LocaleKeys.payments_mark_paid_success);
    }
  }

  Future<void> _voidPaid(
    BuildContext context,
    WidgetRef ref,
    StudentPaymentRecord record,
  ) async {
    if (!await confirmVoidPaid(context) || !context.mounted) return;
    final ok = await _actions(ref).voidPaid(record.obligation);
    if (context.mounted) {
      _report(context, ref, ok, LocaleKeys.payments_void_success);
    }
  }

  Future<void> _stopPlan(BuildContext context, WidgetRef ref) async {
    if (!await confirmStopMonthlyPlan(context) || !context.mounted) return;
    final ok = await _actions(ref).stopPlan(group.id);
    if (context.mounted) {
      _report(context, ref, ok, LocaleKeys.payments_monthly_stopped);
    }
  }

  void _report(BuildContext context, WidgetRef ref, bool ok, String key) {
    final failure = ref.read(paymentActionsControllerProvider).failure;
    showTelmizoSnackBar(
      context,
      ok || failure == null ? key.tr() : appFailureMessage(failure),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(groupPaymentsProvider(group.id));
    final actions = ref.watch(paymentActionsControllerProvider);
    final canCorrect = group.isActive;
    final plan = payments.value?.plan;

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          TelmizoSpacing.lg,
          TelmizoSpacing.margin,
          TelmizoSpacing.xxl * 2,
        ),
        children: [
          if (!group.isActive)
            TelmizoInlineMessage(
              key: const Key('payments-archived-notice'),
              message: LocaleKeys.payments_archived_notice.tr(),
              tone: TelmizoMessageTone.info,
            )
          else if (group.isSuspended)
            TelmizoInlineMessage(
              key: const Key('payments-suspended-notice'),
              message: LocaleKeys.payments_suspended_notice.tr(),
              tone: TelmizoMessageTone.warning,
            )
          else
            TelmizoInlineMessage(
              message: LocaleKeys.payments_record_notice.tr(),
              tone: TelmizoMessageTone.info,
            ),
          const SizedBox(height: TelmizoSpacing.lg),
          ...switch (payments) {
            AsyncData(:final value) when value.isEmpty => [
              PaymentsMessageCard(
                key: const Key('payments-empty'),
                icon: Icons.account_balance_wallet_outlined,
                title: LocaleKeys.payments_empty_title.tr(),
                body: group.acceptsNewEntries
                    ? LocaleKeys.payments_empty_body.tr()
                    : LocaleKeys.payments_empty_archived_body.tr(),
                actionLabel: LocaleKeys.payments_add.tr(),
                onAction: group.acceptsNewEntries ? onAdd : null,
              ),
            ],
            AsyncData(:final value) => [
              PaymentsSummaryCard(totals: value.totals),
              const SizedBox(height: TelmizoSpacing.md),
              MonthlyPlanCard(
                plan: plan,
                isStopping: actions.isRunning(PaymentAction.stopPlan),
                onSetUp: group.acceptsNewEntries
                    ? () => context.router.push(
                        MonthlyPlanRoute(groupId: group.id),
                      )
                    : null,
                onEdit: canCorrect
                    ? () => context.router.push(
                        MonthlyPlanRoute(groupId: group.id),
                      )
                    : null,
                onStop: canCorrect ? () => _stopPlan(context, ref) : null,
              ),
              if (group.acceptsNewEntries) ...[
                const SizedBox(height: TelmizoSpacing.md),
                TelmizoPrimaryButton(
                  key: const Key('add-another-payment'),
                  label: LocaleKeys.payments_add_another.tr(),
                  icon: Icons.add,
                  onPressed: onAdd,
                ),
              ],
              const SizedBox(height: TelmizoSpacing.lg),
              PaymentRecordsSection(
                records: value.records,
                busyRecordId: actions.isBusy ? actions.targetId : null,
                onMarkPaid: canCorrect
                    ? (record) => _markPaid(context, ref, record)
                    : null,
                onVoidPaid: canCorrect
                    ? (record) => _voidPaid(context, ref, record)
                    : null,
              ),
            ],
            AsyncError(:final error) => [
              PaymentsMessageCard(
                key: const Key('payments-error'),
                icon: Icons.cloud_off_outlined,
                title: LocaleKeys.payments_load_error_title.tr(),
                body: appFailureMessage(failureTypeOf(error)),
                actionLabel: LocaleKeys.common_retry.tr(),
                onAction: () => ref.invalidate(groupPaymentsProvider(group.id)),
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
}
