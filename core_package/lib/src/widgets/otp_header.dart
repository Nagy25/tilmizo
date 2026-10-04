import 'package:flutter/material.dart';

import '../../core_package.dart';

/// Badge, icon, title, and masked destination number for the OTP screen.
class OtpHeader extends StatelessWidget {
  const OtpHeader({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.changeNumberLabel,
    required this.changeNumberSemanticLabel,
    required this.maskedPhone,
    required this.onChangeNumber,
  });

  final String badge;
  final String title;
  final String subtitle;
  final String changeNumberLabel;
  final String changeNumberSemanticLabel;
  final String maskedPhone;
  final VoidCallback? onChangeNumber;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Column(
      children: [
        TelmizoPill(
          label: badge,
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
          title,
          style: textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        Text(
          subtitle,
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
                label: changeNumberSemanticLabel,
                button: true,
                excludeSemantics: true,
                child: TextButton.icon(
                  onPressed: onChangeNumber,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(changeNumberLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
