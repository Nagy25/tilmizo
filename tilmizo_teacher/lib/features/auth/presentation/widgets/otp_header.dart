import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Badge, icon, title, and masked destination number for the OTP screen.
class OtpHeader extends StatelessWidget {
  const OtpHeader({
    super.key,
    required this.maskedPhone,
    required this.onChangeNumber,
  });

  final String maskedPhone;
  final VoidCallback? onChangeNumber;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Column(
      children: [
        TelmizoPill(
          label: LocaleKeys.otp_badge.tr(),
          icon: Icons.verified_user_outlined,
          background: TelmizoColors.surfaceContainer,
          foreground: TelmizoColors.primary,
        ),
        const SizedBox(height: TelmizoSpacing.lg),
        Container(
          width: 112,
          height: 112,
          decoration: const BoxDecoration(
            color: TelmizoColors.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const CircleAvatar(
            radius: 40,
            backgroundColor: TelmizoColors.primary,
            foregroundColor: Colors.white,
            child: Icon(Icons.pin_outlined, size: 36),
          ),
        ),
        const SizedBox(height: TelmizoSpacing.lg),
        Text(
          LocaleKeys.otp_title.tr(),
          style: textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        Text(
          LocaleKeys.otp_subtitle.tr(),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: TelmizoColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TelmizoSpacing.md),
        Container(
          padding: const EdgeInsetsDirectional.only(
            start: TelmizoSpacing.lg,
            end: TelmizoSpacing.xs,
          ),
          decoration: const BoxDecoration(
            color: TelmizoColors.surfaceContainer,
            borderRadius: TelmizoRadius.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  maskedPhone,
                  textDirection: TextDirection.ltr,
                  style: textTheme.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: TelmizoSpacing.xs),
              Semantics(
                label: LocaleKeys.otp_change_number_semantics.tr(),
                button: true,
                excludeSemantics: true,
                child: TextButton.icon(
                  onPressed: onChangeNumber,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(LocaleKeys.otp_change_number.tr()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
