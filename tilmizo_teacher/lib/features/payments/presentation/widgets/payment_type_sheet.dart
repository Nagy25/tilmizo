import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// What the teacher chose to add from the payments screen.
enum PaymentAddKind { monthly, oneTime, session }

/// The add-payment type picker. A session amount is created together with a
/// new session, never as a disconnected group payment.
Future<PaymentAddKind?> showPaymentTypeSheet(
  BuildContext context, {
  required bool hasMonthlyPlan,
}) => showModalBottomSheet<PaymentAddKind>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _PaymentTypeSheet(hasMonthlyPlan: hasMonthlyPlan),
);

class _PaymentTypeSheet extends StatelessWidget {
  const _PaymentTypeSheet({required this.hasMonthlyPlan});

  final bool hasMonthlyPlan;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final options = [
      (
        kind: PaymentAddKind.monthly,
        icon: Icons.calendar_month_outlined,
        title: LocaleKeys.payments_type_monthly.tr(),
        body: hasMonthlyPlan
            ? LocaleKeys.payments_type_monthly_active.tr()
            : LocaleKeys.payments_type_monthly_body.tr(),
        enabled: !hasMonthlyPlan,
      ),
      (
        kind: PaymentAddKind.oneTime,
        icon: Icons.receipt_long_outlined,
        title: LocaleKeys.payments_type_one_time.tr(),
        body: LocaleKeys.payments_type_one_time_body.tr(),
        enabled: true,
      ),
      (
        kind: PaymentAddKind.session,
        icon: Icons.event_outlined,
        title: LocaleKeys.payments_type_session.tr(),
        body: LocaleKeys.payments_type_session_body.tr(),
        enabled: true,
      ),
    ];
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
              LocaleKeys.payments_type_sheet_title.tr(),
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: TelmizoSpacing.xs),
            Text(
              LocaleKeys.payments_type_sheet_subtitle.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.md),
            for (final option in options)
              ListTile(
                key: Key('payment-type-${option.kind.name}'),
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: TelmizoColors.primaryTint,
                  foregroundColor: TelmizoColors.primary,
                  child: Icon(option.icon),
                ),
                title: Text(option.title),
                subtitle: Text(option.body),
                trailing: Icon(
                  option.enabled ? Icons.chevron_right : Icons.lock_outline,
                ),
                enabled: option.enabled,
                onTap: option.enabled
                    ? () => Navigator.of(context).pop(option.kind)
                    : null,
              ),
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              message: LocaleKeys.payments_record_notice.tr(),
              tone: TelmizoMessageTone.info,
            ),
          ],
        ),
      ),
    );
  }
}
