import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

import 'access_labels.dart';

/// Tappable list row for a request or a student.
class AccessListCard extends StatelessWidget {
  const AccessListCard({
    super.key,
    required this.name,
    required this.phone,
    required this.semanticLabel,
    required this.pill,
    required this.detail,
    required this.onTap,
  });

  final String? name;
  final String phone;
  final String semanticLabel;
  final Widget pill;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: TelmizoRadius.lgAll,
          child: Ink(
            padding: const EdgeInsets.all(TelmizoSpacing.md),
            decoration: BoxDecoration(
              color: TelmizoColors.surfaceContainerLowest,
              borderRadius: TelmizoRadius.lgAll,
              border: Border.all(color: TelmizoColors.border),
              boxShadow: TelmizoShadows.level1,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentDisplayName(name),
                        style: textTheme.titleMedium,
                      ),
                      Text(
                        EgyptianPhone.mask(phone),
                        textDirection: TextDirection.ltr,
                        style: textTheme.bodySmall?.copyWith(
                          color: TelmizoColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: TelmizoSpacing.sm),
                      Text(detail, style: textTheme.bodySmall),
                      const SizedBox(height: TelmizoSpacing.sm),
                      pill,
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
