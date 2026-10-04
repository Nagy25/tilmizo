import 'package:flutter/material.dart';

import '../../core_package.dart';

/// Optional avatar display. Uploading is not available yet, so this card is
/// informational and noninteractive.
class TelmizoAvatarCard extends StatelessWidget {
  const TelmizoAvatarCard({
    super.key,
    required this.title,
    required this.body,
    required this.semanticLabel,
    this.avatarUrl,
  });

  final String title;
  final String body;
  final String semanticLabel;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoCard(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      child: Row(
        children: [
          TelmizoAvatar(
            avatarUrl: avatarUrl,
            size: 64,
            semanticLabel: semanticLabel,
          ),
          const SizedBox(width: TelmizoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
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
