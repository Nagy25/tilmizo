import 'package:flutter/material.dart';

import '../../core_package.dart';

/// Brand block from the Stitch splash: badge, framed logo, name, and tagline.
class TelmizoSplashBrand extends StatelessWidget {
  const TelmizoSplashBrand({
    super.key,
    required this.badge,
    required this.name,
    required this.audience,
    required this.tagline,
    required this.logoSemanticLabel,
  });

  final String badge;
  final String name;

  /// Accent word after the name, such as "for teachers".
  final String audience;
  final String tagline;
  final String logoSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TelmizoPill(
            label: badge,
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
            child: TelmizoLogo(size: 96, semanticLabel: logoSemanticLabel),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: name),
                const TextSpan(text: ' '),
                TextSpan(
                  text: audience,
                  style: const TextStyle(color: TelmizoColors.primary),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: textTheme.displayLarge,
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            tagline,
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
