import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/telmizo_logo.dart';
import '../../../../generated/locale_keys.g.dart';

/// Brand block from the Stitch splash: badge, framed logo, name, and tagline.
class SplashBrand extends StatelessWidget {
  const SplashBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TelmizoPill(
            label: LocaleKeys.splash_badge.tr(),
            icon: Icons.auto_awesome_outlined,
            background: TelmizoColors.primaryTint,
            foreground: TelmizoColors.primary,
          ),
          const SizedBox(height: TelmizoSpacing.xl),
          Container(
            padding: const EdgeInsets.all(TelmizoSpacing.md),
            decoration: BoxDecoration(
              color: TelmizoColors.surfaceContainerLowest,
              borderRadius: TelmizoRadius.xlAll,
              boxShadow: [
                BoxShadow(
                  color: TelmizoColors.primary.withValues(alpha: 0.18),
                  blurRadius: 48,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const TelmizoLogo(size: 96),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: LocaleKeys.brand_name.tr()),
                const TextSpan(text: ' '),
                TextSpan(
                  text: LocaleKeys.brand_teacher.tr(),
                  style: const TextStyle(color: TelmizoColors.primary),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: textTheme.displayLarge,
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            LocaleKeys.splash_tagline.tr(),
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
