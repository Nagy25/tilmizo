import 'package:flutter/material.dart';

import '../../core_package.dart';

/// Tinted explanatory box with a circular icon, as in the Stitch auth screens.
class TelmizoInfoBox extends StatelessWidget {
  const TelmizoInfoBox({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.background = TelmizoColors.surfaceContainer,
    this.iconBackground = TelmizoColors.primary,
    this.titleColor = TelmizoColors.onSurface,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color background;
  final Color iconBackground;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: TelmizoRadius.lgAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: iconBackground,
            foregroundColor: Colors.white,
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: TelmizoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(color: titleColor),
                ),
                const SizedBox(height: TelmizoSpacing.xs),
                Text(
                  body,
                  style: textTheme.bodySmall?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
