import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/teacher_group.dart';
import 'group_status_pill.dart';

/// Group name, status, and creation date.
class GroupOverviewCard extends StatelessWidget {
  const GroupOverviewCard({super.key, required this.group, this.onEdit});

  final TeacherGroup group;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final created = DateFormat.yMMMd(context.locale.toLanguageTag())
        .format(group.createdAt.toLocal());

    return TelmizoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(group.name, style: textTheme.headlineSmall)),
              const SizedBox(width: TelmizoSpacing.sm),
              GroupStatusPill(
                isActive: group.isActive,
                isSuspended: group.isSuspended,
              ),
              if (onEdit != null)
                IconButton(
                  key: const Key('group-edit'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: LocaleKeys.edit_group_title.tr(),
                ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: TelmizoColors.onSurfaceVariant,
              ),
              const SizedBox(width: TelmizoSpacing.xs),
              Expanded(
                child: Text(
                  LocaleKeys.group_created_on.tr(args: [created]),
                  style: textTheme.bodySmall?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
