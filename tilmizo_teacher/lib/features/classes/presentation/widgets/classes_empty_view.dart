import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

/// A centered illustrated message for an empty session list.
class ClassesEmptyView extends StatelessWidget {
  const ClassesEmptyView({
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
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  TelmizoColors.primaryFixed,
                  TelmizoColors.surfaceContainerHighest,
                  TelmizoColors.tertiaryContainer,
                ],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
            ),
            child: Icon(icon, size: 52, color: TelmizoColors.primary),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
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
