import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Group name, subject • grade, and teacher in the Stitch pill card style.
class GroupSummaryCard extends StatelessWidget {
  const GroupSummaryCard({
    super.key,
    required this.name,
    this.subject,
    this.grade,
    this.teacherName,
  });

  final String name;
  final String? subject;
  final String? grade;
  final String? teacherName;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final details = [subject, grade].whereType<String>().join(' • ');
    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.lg),
      decoration: const BoxDecoration(
        color: TelmizoColors.surfaceContainerLow,
        borderRadius: TelmizoRadius.xlAll,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: TelmizoColors.primary,
            foregroundColor: TelmizoColors.onPrimary,
            child: Icon(Icons.school_outlined, size: 28),
          ),
          const SizedBox(width: TelmizoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: textTheme.labelMedium?.copyWith(
                      color: TelmizoColors.primary,
                    ),
                  ),
                Text(name, style: textTheme.titleLarge),
                if (teacherName case final teacher?)
                  Text(
                    LocaleKeys.teacher_label.tr(args: [teacher]),
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
