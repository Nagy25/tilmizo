import 'package:flutter/material.dart';

import 'telmizo_colors.dart';
import 'telmizo_radius.dart';
import 'telmizo_shadows.dart';
import 'telmizo_spacing.dart';

/// Constrains a mobile-first layout to [TelmizoSpacing.maxContentWidth] and
/// centers it on wide screens such as the web.
class TelmizoMobileFrame extends StatelessWidget {
  const TelmizoMobileFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TelmizoColors.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TelmizoSpacing.maxContentWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// White level-1 surface with the Stitch border and ambient shadow.
class TelmizoCard extends StatelessWidget {
  const TelmizoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TelmizoSpacing.lg),
    this.color = TelmizoColors.surfaceContainerLowest,
    this.borderRadius = TelmizoRadius.xlAll,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: TelmizoColors.border),
        boxShadow: TelmizoShadows.level1,
      ),
      child: child,
    );
  }
}

/// Compact pill used for status tags.
class TelmizoPill extends StatelessWidget {
  const TelmizoPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TelmizoSpacing.md - 4,
        vertical: TelmizoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: TelmizoRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: TelmizoSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
