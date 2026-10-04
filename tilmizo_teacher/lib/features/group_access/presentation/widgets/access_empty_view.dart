import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

class AccessEmptyView extends StatelessWidget {
  const AccessEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoCard(
      padding: const EdgeInsets.all(TelmizoSpacing.xl),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: TelmizoColors.primaryTint,
            foregroundColor: TelmizoColors.primary,
            child: Icon(icon, size: 36),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          Text(
            title,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
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
      ),
    );
  }
}
