import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../generated/locale_keys.g.dart';

/// Phone entry with a fixed Egyptian `+20` prefix at the visual start. Digits
/// are always laid out left-to-right so numbers stay readable in RTL.
class EgyptianPhoneField extends StatelessWidget {
  const EgyptianPhoneField({
    super.key,
    required this.controller,
    required this.isValid,
    required this.enabled,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isValid;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.end,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹ +\-]')),
        LengthLimitingTextInputFormatter(17),
      ],
      style: textTheme.headlineSmall?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: null,
        hintText: LocaleKeys.login_phone_hint.tr(),
        hintTextDirection: TextDirection.ltr,
        fillColor: TelmizoColors.surfaceContainerLow,
        errorText: errorText,
        prefixIcon: const _CountryPrefix(),
        suffixIcon: isValid
            ? const Padding(
                padding: EdgeInsetsDirectional.only(end: TelmizoSpacing.sm),
                child: Icon(Icons.check_circle, color: TelmizoColors.primary),
              )
            : null,
      ),
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: LocaleKeys.login_country_code_semantics.tr(),
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: TelmizoSpacing.sm),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: TelmizoSpacing.md - 4,
        ),
        decoration: const BoxDecoration(
          border: BorderDirectional(
            end: BorderSide(color: TelmizoColors.outlineVariant),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🇪🇬', style: TextStyle(fontSize: 20)),
            const SizedBox(width: TelmizoSpacing.xs + 2),
            Text(
              EgyptianPhone.countryCode,
              textDirection: TextDirection.ltr,
              style: context.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
