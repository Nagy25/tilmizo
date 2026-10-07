import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/teacher_group.dart';
import 'group_status_pill.dart';

/// Dashboard card for one group, showing only schema-backed fields.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, required this.onTap});

  final TeacherGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final details = [
      group.subject,
      group.grade,
    ].whereType<String>().join(' • ');
    final code = group.inviteCode;

    return Semantics(
      button: true,
      label: LocaleKeys.group_open_semantics.tr(args: [group.name]),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: TelmizoRadius.xlAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: TelmizoRadius.xlAll,
          child: Ink(
            padding: const EdgeInsets.all(TelmizoSpacing.lg),
            decoration: BoxDecoration(
              color: TelmizoColors.surfaceContainerLowest,
              borderRadius: TelmizoRadius.xlAll,
              border: Border.all(color: TelmizoColors.border),
              boxShadow: TelmizoShadows.level1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(group.name, style: textTheme.titleLarge),
                    ),
                    const SizedBox(width: TelmizoSpacing.sm),
                    GroupStatusPill(
                      isActive: group.isActive,
                      isSuspended: group.isSuspended,
                    ),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: TelmizoSpacing.xs),
                  Text(
                    details,
                    style: textTheme.bodyMedium?.copyWith(
                      color: TelmizoColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: TelmizoSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TelmizoSpacing.md,
                          vertical: TelmizoSpacing.sm,
                        ),
                        decoration: const BoxDecoration(
                          color: TelmizoColors.surfaceContainerLow,
                          borderRadius: TelmizoRadius.pillAll,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              code == null ? Icons.block : Icons.key_outlined,
                              size: 18,
                              color: TelmizoColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: TelmizoSpacing.xs),
                            Flexible(
                              child: Text(
                                code == null
                                    ? LocaleKeys.group_no_code.tr()
                                    : LocaleKeys.group_code_label.tr(
                                        args: ['\u2066$code\u2069'],
                                      ),
                                style: textTheme.labelLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: TelmizoSpacing.sm),
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: TelmizoColors.surfaceContainerLow,
                      foregroundColor: TelmizoColors.onSurface,
                      child: Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
