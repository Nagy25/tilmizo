import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Confirms voiding a paid mark. The receipt is kept for audit.
Future<bool> confirmVoidPaid(BuildContext context) => _confirm(
  context,
  title: LocaleKeys.payments_void_title.tr(),
  body: LocaleKeys.payments_void_body.tr(),
  confirmLabel: LocaleKeys.payments_void_confirm.tr(),
  confirmKey: const Key('confirm-void-paid'),
);

/// Confirms stopping the monthly plan. Existing records are kept.
Future<bool> confirmStopMonthlyPlan(BuildContext context) => _confirm(
  context,
  title: LocaleKeys.payments_monthly_stop_title.tr(),
  body: LocaleKeys.payments_monthly_stop_body.tr(),
  confirmLabel: LocaleKeys.payments_monthly_stop_confirm.tr(),
  confirmKey: const Key('confirm-stop-plan'),
);

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required Key confirmKey,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(LocaleKeys.common_cancel.tr()),
        ),
        TextButton(
          key: confirmKey,
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: TelmizoColors.error),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
