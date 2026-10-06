import 'package:flutter/material.dart';

import '../../core_package.dart';

/// Optional avatar display with an optional edit action.
class TelmizoAvatarCard extends StatelessWidget {
  const TelmizoAvatarCard({
    super.key,
    required this.title,
    required this.body,
    required this.semanticLabel,
    this.avatarUrl,
    this.fullName,
    this.avatarRevision,
    this.onEdit,
    this.editTooltip,
    this.isUpdating = false,
  });

  final String title;
  final String body;
  final String semanticLabel;
  final String? avatarUrl;
  final String? fullName;
  final String? avatarRevision;
  final VoidCallback? onEdit;
  final String? editTooltip;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoCard(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      child: Row(
        children: [
          TelmizoAvatar(
            avatarUrl: avatarUrl,
            fullName: fullName,
            avatarRevision: avatarRevision,
            size: 64,
            semanticLabel: semanticLabel,
            onEdit: onEdit,
            editTooltip: editTooltip,
            isUpdating: isUpdating,
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
