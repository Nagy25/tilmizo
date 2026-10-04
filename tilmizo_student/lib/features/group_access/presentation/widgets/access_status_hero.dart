import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

/// The large status illustration, badge, title, and explanation used by the
/// group status screens (Stitch "request status" layout).
class AccessStatusHero extends StatelessWidget {
  const AccessStatusHero({
    super.key,
    required this.icon,
    required this.badge,
    required this.title,
    required this.body,
    this.tone = TelmizoMessageTone.warning,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String body;
  final TelmizoMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final (
      halo,
      circle,
      foreground,
      pillBackground,
      pillForeground,
    ) = switch (tone) {
      TelmizoMessageTone.success => (
        TelmizoColors.surfaceContainerHigh,
        TelmizoColors.primaryFixed,
        TelmizoColors.primaryPressed,
        TelmizoColors.successContainer,
        TelmizoColors.success,
      ),
      TelmizoMessageTone.error => (
        TelmizoColors.errorContainer.withValues(alpha: 0.5),
        TelmizoColors.errorContainer,
        TelmizoColors.error,
        TelmizoColors.errorContainer,
        TelmizoColors.onErrorContainer,
      ),
      TelmizoMessageTone.info => (
        TelmizoColors.surfaceContainerHigh,
        TelmizoColors.secondaryContainer,
        TelmizoColors.onSecondaryContainer,
        TelmizoColors.secondaryContainer,
        TelmizoColors.onSecondaryContainer,
      ),
      TelmizoMessageTone.warning => (
        TelmizoColors.surfaceContainerHigh,
        TelmizoColors.primaryFixed,
        TelmizoColors.primaryPressed,
        TelmizoColors.tertiaryContainer,
        TelmizoColors.onTertiaryContainer,
      ),
    };

    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(color: halo, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: CircleAvatar(
            radius: 44,
            backgroundColor: circle,
            foregroundColor: foreground,
            child: Icon(icon, size: 44),
          ),
        ),
        const SizedBox(height: TelmizoSpacing.md),
        TelmizoPill(
          label: badge,
          background: pillBackground,
          foreground: pillForeground,
        ),
        const SizedBox(height: TelmizoSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        Text(
          body,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: TelmizoColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
