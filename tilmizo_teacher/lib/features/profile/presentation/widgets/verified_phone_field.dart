import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// The verified phone number, displayed read-only.
class VerifiedPhoneField extends StatelessWidget {
  const VerifiedPhoneField({super.key, required this.phone});

  /// Egyptian E.164 number.
  final String phone;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoFormField(
      label: LocaleKeys.profile_phone_label.tr(),
      trailing: const Icon(
        Icons.lock_outline,
        size: 18,
        color: TelmizoColors.onSurfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('verified-phone'),
            initialValue: EgyptianPhone.formatLocal(phone),
            readOnly: true,
            enableInteractiveSelection: false,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.end,
            style: textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              fillColor: TelmizoColors.surfaceContainerLow,
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: TelmizoSpacing.md,
                  end: TelmizoSpacing.sm,
                ),
                child: Text(
                  EgyptianPhone.countryCode,
                  textDirection: TextDirection.ltr,
                  style: textTheme.titleMedium,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(height: TelmizoSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: TelmizoColors.onSurfaceVariant,
              ),
              const SizedBox(width: TelmizoSpacing.xs),
              Expanded(
                child: Text(
                  LocaleKeys.profile_phone_note.tr(),
                  style: textTheme.bodySmall?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
