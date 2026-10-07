import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

/// Empty, error and blocked states inside payment lists.
class PaymentsMessageCard extends StatelessWidget {
  const PaymentsMessageCard({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Column(
      children: [
        Icon(icon, size: 40, color: TelmizoColors.onSurfaceVariant),
        const SizedBox(height: TelmizoSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium,
        ),
        if (body case final body?) ...[
          const SizedBox(height: TelmizoSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: TelmizoSpacing.md),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}
