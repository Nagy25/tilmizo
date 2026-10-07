import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../classes/presentation/widgets/active_group_gate.dart';
import '../../domain/payment_models.dart';
import '../controllers/payments_providers.dart';
import '../widgets/payment_amount_field.dart';

/// Creates a group-wide one-time amount for every active student.
@RoutePage()
class OneTimePaymentScreen extends ConsumerStatefulWidget {
  const OneTimePaymentScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  ConsumerState<OneTimePaymentScreen> createState() =>
      _OneTimePaymentScreenState();
}

class _OneTimePaymentScreenState extends ConsumerState<OneTimePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = PaymentAmountField.read(_amount);
    if (amount == null) return;
    final created = await ref
        .read(paymentActionsControllerProvider.notifier)
        .createOneTime(
          widget.groupId,
          OneTimePaymentDraft(
            title: _title.text.trim(),
            description: trimToNull(_description.text),
            amount: amount,
          ),
        );
    if (!created || !mounted) return;
    showTelmizoSnackBar(context, LocaleKeys.payments_one_time_created.tr());
    await context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentActionsControllerProvider);
    final enabled = !state.isBusy;
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.payments_one_time_title.tr(),
        showBack: true,
      ),
      body: ActiveGroupGate(
        groupId: widget.groupId,
        blockSuspended: true,
        archivedMessage: LocaleKeys.payments_archived_notice.tr(),
        suspendedMessage: LocaleKeys.payments_suspended_notice.tr(),
        builder: (group) => Form(
          key: _formKey,
          child: TelmizoScrollBody(
            children: [
              Text(group.name, style: context.textTheme.titleLarge),
              const SizedBox(height: TelmizoSpacing.md),
              TelmizoInlineMessage(
                message: LocaleKeys.payments_one_time_intro.tr(),
                tone: TelmizoMessageTone.info,
              ),
              const SizedBox(height: TelmizoSpacing.lg),
              TelmizoFormField(
                label: LocaleKeys.payments_one_time_name_label.tr(),
                isRequired: true,
                child: TextFormField(
                  key: const Key('one-time-payment-title'),
                  controller: _title,
                  enabled: enabled,
                  maxLength: OneTimePaymentDraft.maxTitleLength,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.payments_one_time_name_hint.tr(),
                  ),
                  validator: (value) {
                    final title = value?.trim() ?? '';
                    if (title.isEmpty) {
                      return LocaleKeys.payments_one_time_name_empty.tr();
                    }
                    return title.length > OneTimePaymentDraft.maxTitleLength
                        ? LocaleKeys.payments_one_time_name_too_long.tr()
                        : null;
                  },
                ),
              ),
              const SizedBox(height: TelmizoSpacing.md),
              PaymentAmountField(controller: _amount, enabled: enabled),
              const SizedBox(height: TelmizoSpacing.md),
              TelmizoFormField(
                label: LocaleKeys.payments_description_label.tr(),
                qualifier: LocaleKeys.common_optional.tr(),
                child: TextFormField(
                  key: const Key('one-time-payment-description'),
                  controller: _description,
                  enabled: enabled,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: OneTimePaymentDraft.maxDescriptionLength,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.payments_description_hint.tr(),
                  ),
                  validator: (value) =>
                      (value?.length ?? 0) >
                          OneTimePaymentDraft.maxDescriptionLength
                      ? LocaleKeys.payments_description_too_long.tr()
                      : null,
                ),
              ),
              if (state.failure case final failure?) ...[
                const SizedBox(height: TelmizoSpacing.md),
                TelmizoInlineMessage(message: appFailureMessage(failure)),
              ],
              const SizedBox(height: TelmizoSpacing.xl),
              TelmizoPrimaryButton(
                key: const Key('create-one-time-payment'),
                label: LocaleKeys.payments_one_time_submit.tr(),
                icon: Icons.add_card_outlined,
                isLoading: state.isRunning(PaymentAction.createOneTime),
                onPressed: enabled ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
