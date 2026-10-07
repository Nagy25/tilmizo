import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../classes/presentation/widgets/active_group_gate.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../domain/payment_models.dart';
import '../controllers/payments_providers.dart';
import '../widgets/due_day_field.dart';
import '../widgets/monthly_due_choice_field.dart';
import '../widgets/payment_amount_field.dart';
import '../widgets/payments_message_card.dart';

/// Configures the group's single monthly plan, or edits its amount and due
/// day. A
/// suspended group may edit an existing plan but cannot start a new one.
@RoutePage()
class MonthlyPlanScreen extends ConsumerWidget {
  const MonthlyPlanScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(groupPaymentsProvider(groupId));
    final plan = payments.value?.plan;
    return Scaffold(
      appBar: AppHeader(
        title: plan == null
            ? LocaleKeys.payments_monthly_form_title.tr()
            : LocaleKeys.payments_monthly_form_edit_title.tr(),
        showBack: true,
      ),
      body: ActiveGroupGate(
        groupId: groupId,
        archivedMessage: LocaleKeys.payments_archived_notice.tr(),
        builder: (group) => payments.when(
          skipLoadingOnRefresh: true,
          loading: () => const TelmizoLoadingView(),
          error: (error, _) => TelmizoErrorView(
            title: LocaleKeys.payments_load_error_title.tr(),
            message: appFailureMessage(failureTypeOf(error)),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(groupPaymentsProvider(groupId)),
          ),
          data: (payments) => payments.plan == null && group.isSuspended
              ? Padding(
                  padding: const EdgeInsets.all(TelmizoSpacing.margin),
                  child: PaymentsMessageCard(
                    key: const Key('payments-new-blocked'),
                    icon: Icons.pause_circle_outline,
                    title: LocaleKeys.payments_new_blocked_title.tr(),
                    body: LocaleKeys.payments_suspended_notice.tr(),
                  ),
                )
              : _MonthlyPlanForm(group: group, plan: payments.plan),
        ),
      ),
    );
  }
}

class _MonthlyPlanForm extends ConsumerStatefulWidget {
  const _MonthlyPlanForm({required this.group, required this.plan});

  final TeacherGroup group;
  final MonthlyPaymentPlan? plan;

  @override
  ConsumerState<_MonthlyPlanForm> createState() => _MonthlyPlanFormState();
}

class _MonthlyPlanFormState extends ConsumerState<_MonthlyPlanForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.plan?.amount.plainText,
  );
  late var _dueDay = widget.plan?.dueDay ?? MonthlyPaymentPlan.minDueDay;
  late var _dueChoice = widget.plan?.dueMode == MonthlyDueMode.joinDay
      ? MonthlyDueChoice.joinDay
      : _dueDay == 1
      ? MonthlyDueChoice.firstDay
      : MonthlyDueChoice.specificDay;

  MonthlyDueMode get _dueMode => _dueChoice == MonthlyDueChoice.joinDay
      ? MonthlyDueMode.joinDay
      : MonthlyDueMode.fixedDay;

  int get _effectiveDueDay =>
      _dueChoice == MonthlyDueChoice.specificDay ? _dueDay : 1;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = PaymentAmountField.read(_amount);
    if (amount == null) return;
    final plan = widget.plan;
    if (plan != null &&
        amount == plan.amount &&
        _dueMode == plan.dueMode &&
        (_dueMode == MonthlyDueMode.joinDay ||
            _effectiveDueDay == plan.dueDay)) {
      await context.router.maybePop();
      return;
    }
    final saved = await ref
        .read(paymentActionsControllerProvider.notifier)
        .configurePlan(
          widget.group.id,
          amount,
          dueDay: _effectiveDueDay,
          dueMode: _dueMode,
        );
    if (!saved || !mounted) return;
    showTelmizoSnackBar(context, LocaleKeys.payments_monthly_saved.tr());
    await context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentActionsControllerProvider);
    final plan = widget.plan;
    return Form(
      key: _formKey,
      child: TelmizoScrollBody(
        children: [
          Text(widget.group.name, style: context.textTheme.titleLarge),
          const SizedBox(height: TelmizoSpacing.md),
          TelmizoInlineMessage(
            message: LocaleKeys.payments_monthly_form_intro.tr(),
            tone: TelmizoMessageTone.info,
          ),
          if (plan != null) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              key: const Key('monthly-plan-edit-notice'),
              title: LocaleKeys.payments_monthly_current.tr(
                args: [plan.amount.displayText],
              ),
              message: [
                LocaleKeys.payments_monthly_current_due.tr(
                  args: [
                    plan.dueMode == MonthlyDueMode.joinDay
                        ? LocaleKeys.payments_due_choice_join.tr()
                        : LocaleKeys.payments_due_day_value.tr(
                            args: ['${plan.dueDay}'],
                          ),
                  ],
                ),
                LocaleKeys.payments_monthly_edit_notice.tr(),
              ].join('\n'),
              tone: TelmizoMessageTone.warning,
            ),
          ],
          const SizedBox(height: TelmizoSpacing.lg),
          PaymentAmountField(
            controller: _amount,
            enabled: !state.isBusy,
            label: LocaleKeys.payments_amount_monthly_label.tr(),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          MonthlyDueChoiceField(
            value: _dueChoice,
            enabled: !state.isBusy,
            onChanged: (choice) => setState(() => _dueChoice = choice),
          ),
          if (_dueChoice == MonthlyDueChoice.specificDay) ...[
            const SizedBox(height: TelmizoSpacing.md),
            DueDayField(
              value: _dueDay,
              enabled: !state.isBusy,
              onChanged: (day) => setState(() => _dueDay = day),
            ),
          ],
          if (state.failure case final failure?) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(message: appFailureMessage(failure)),
          ],
          const SizedBox(height: TelmizoSpacing.xl),
          TelmizoPrimaryButton(
            key: const Key('save-monthly-plan'),
            label: LocaleKeys.payments_monthly_save.tr(),
            icon: Icons.save_outlined,
            isLoading: state.isRunning(PaymentAction.configurePlan),
            onPressed: state.isBusy ? null : _save,
          ),
        ],
      ),
    );
  }
}
