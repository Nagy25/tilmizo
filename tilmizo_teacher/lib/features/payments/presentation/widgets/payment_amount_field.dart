import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../generated/locale_keys.g.dart';
import '../payment_labels.dart';

/// An EGP amount with at most two decimal places. When [isRequired] is
/// false an empty field is valid and means "no amount".
class PaymentAmountField extends StatelessWidget {
  const PaymentAmountField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.isRequired = true,
    this.enabled = true,
    this.fieldKey = const Key('payment-amount-field'),
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool isRequired;
  final bool enabled;
  final Key fieldKey;

  /// The parsed amount, or null when the field is empty or invalid.
  static EgpAmount? read(TextEditingController controller) =>
      EgpAmount.parse(controller.text).amount;

  @override
  Widget build(BuildContext context) => TelmizoFormField(
    label: label ?? LocaleKeys.payments_amount_label.tr(),
    isRequired: isRequired,
    qualifier: isRequired ? null : LocaleKeys.common_optional.tr(),
    child: TextFormField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textDirection: TextDirection.ltr,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫٬]')),
        LengthLimitingTextInputFormatter(16),
      ],
      decoration: InputDecoration(
        hintText: hint ?? LocaleKeys.payments_amount_hint.tr(),
        prefixIcon: const Icon(Icons.payments_outlined),
      ),
      validator: (value) {
        if (!isRequired && (value?.trim().isEmpty ?? true)) return null;
        return amountIssueMessage(EgpAmount.parse(value).issue);
      },
    ),
  );
}
