import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/teacher_group.dart';

/// Group totals derived from schema-backed fields only.
class GroupsSummaryCard extends StatelessWidget {
  const GroupsSummaryCard({super.key, required this.groups});

  final List<TeacherGroup> groups;

  @override
  Widget build(BuildContext context) {
    final active = groups.where((group) => group.isActive).length;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.lg),
      decoration: const BoxDecoration(
        color: TelmizoColors.surfaceContainerLow,
        borderRadius: TelmizoRadius.xlAll,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: TelmizoColors.primaryTint,
            foregroundColor: TelmizoColors.primary,
            child: Icon(Icons.groups_outlined, size: 32),
          ),
          const SizedBox(width: TelmizoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.groups_count.plural(groups.length),
                  style: textTheme.headlineMedium,
                ),
                Text(
                  LocaleKeys.groups_active_summary.tr(
                    namedArgs: {
                      'active': '$active',
                      'inactive': '${groups.length - active}',
                    },
                  ),
                  style: textTheme.bodyMedium?.copyWith(
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
