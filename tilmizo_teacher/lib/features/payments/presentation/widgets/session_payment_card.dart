import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../classes/domain/class_session.dart';
import '../controllers/payments_providers.dart';
import 'payment_amount_field.dart';

/// The session's amount, or an action to attach one once when the session
/// has no active payment item. There is no schedule-wide pricing.
class SessionPaymentCard extends ConsumerWidget {
  const SessionPaymentCard({super.key, required this.session});

  final ClassSession session;

  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final amount = await showModalBottomSheet<EgpAmount>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AttachPaymentSheet(),
    );
    if (amount == null || !context.mounted) return;
    final ok = await ref
        .read(paymentActionsControllerProvider.notifier)
        .attachSession(
          groupId: session.group.id,
          sessionId: session.id,
          amount: amount,
        );
    if (!context.mounted) return;
    final failure = ref.read(paymentActionsControllerProvider).failure;
    showTelmizoSnackBar(
      context,
      ok || failure == null
          ? LocaleKeys.payments_session_added.tr()
          : appFailureMessage(failure),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref.watch(sessionPaymentAmountProvider(session.id));
    final busy = ref
        .watch(paymentActionsControllerProvider)
        .isRunning(PaymentAction.attachSession);
    final textTheme = context.textTheme;
    final (text, canAttach) = switch (amount) {
      AsyncData(value: final value?) => (
        LocaleKeys.payments_session_amount_value.tr(args: [value.displayText]),
        false,
      ),
      AsyncData() => (
        LocaleKeys.payments_session_none.tr(),
        session.canAttachPayment,
      ),
      AsyncError() => (LocaleKeys.payments_session_load_error.tr(), false),
      _ => (null, false),
    };
    return TelmizoCard(
      key: const Key('session-payment-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: TelmizoColors.primary,
              ),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Text(
                  LocaleKeys.payments_session_card_title.tr(),
                  style: textTheme.titleMedium,
                ),
              ),
              if (amount is AsyncError)
                IconButton(
                  tooltip: LocaleKeys.common_retry.tr(),
                  onPressed: () =>
                      ref.invalidate(sessionPaymentAmountProvider(session.id)),
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          if (text == null)
            const LinearProgressIndicator()
          else
            Text(text, style: textTheme.bodyMedium),
          if (canAttach) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoSecondaryButton(
              key: const Key('attach-session-payment'),
              label: LocaleKeys.payments_session_add.tr(),
              icon: Icons.add_card_outlined,
              isLoading: busy,
              onPressed: busy ? null : () => _attach(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachPaymentSheet extends StatefulWidget {
  const _AttachPaymentSheet();

  @override
  State<_AttachPaymentSheet> createState() => _AttachPaymentSheetState();
}

class _AttachPaymentSheetState extends State<_AttachPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(PaymentAmountField.read(_amount));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        TelmizoSpacing.margin,
        0,
        TelmizoSpacing.margin,
        TelmizoSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.payments_session_add.tr(),
              style: context.textTheme.headlineSmall,
            ),
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              message: LocaleKeys.payments_session_add_body.tr(),
              tone: TelmizoMessageTone.info,
            ),
            const SizedBox(height: TelmizoSpacing.md),
            PaymentAmountField(controller: _amount),
            const SizedBox(height: TelmizoSpacing.lg),
            TelmizoPrimaryButton(
              key: const Key('confirm-attach-session-payment'),
              label: LocaleKeys.payments_session_add.tr(),
              icon: Icons.check,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
