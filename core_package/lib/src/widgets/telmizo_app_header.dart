import 'package:flutter/material.dart';

import '../../core_package.dart';

/// Translucent top bar from the Stitch screens: optional back button, brand
/// mark, title and subtitle at the start, and an optional trailing action.
class TelmizoAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const TelmizoAppHeader({
    super.key,
    required this.title,
    required this.logoSemanticLabel,
    this.backTooltip,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String logoSemanticLabel;
  final String? backTooltip;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    // The bar has a fixed height, so its labels scale up to a bounded factor;
    // screen content below still follows the full system text size.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Material(
        color: TelmizoColors.surface,
        elevation: 0,
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: TelmizoSpacing.sm),
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
              color: TelmizoColors.surface,
            ),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    tooltip: backTooltip,
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: TelmizoColors.surfaceContainerLow,
                    ),
                    icon: const Icon(Icons.arrow_back),
                  )
                else
                  const SizedBox(width: TelmizoSpacing.sm),
                const SizedBox(width: TelmizoSpacing.sm),
                TelmizoLogo(size: 40, semanticLabel: logoSemanticLabel),
                const SizedBox(width: TelmizoSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          color: TelmizoColors.primary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: TelmizoColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
                const SizedBox(width: TelmizoSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
