import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../../groups/presentation/widgets/group_status_pill.dart';

/// Group context for the classes list: status, subject, and live counts.
class ClassesGroupHeader extends ConsumerWidget {
  const ClassesGroupHeader({super.key, required this.group});

  final TeacherGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = context.textTheme;
    final members = ref.watch(groupMembersProvider(group.id));
    final activeCount = switch (members) {
      AsyncData(value: final list) => list.where((m) => m.isActive).length,
      _ => null,
    };
    final details = [?group.subject, ?group.grade].join(' • ');
    return TelmizoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: TelmizoColors.secondaryContainer,
                foregroundColor: TelmizoColors.secondary,
                child: Icon(Icons.school_outlined),
              ),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: textTheme.titleLarge),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        style: textTheme.bodySmall?.copyWith(
                          color: TelmizoColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              GroupStatusPill(isActive: group.isActive),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 20,
                color: TelmizoColors.primary,
              ),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Text(
                  activeCount == null
                      ? LocaleKeys.all_students_count_unknown.tr()
                      : LocaleKeys.active_students_count.plural(activeCount),
                  style: textTheme.bodyMedium,
                ),
              ),
              if (group.isActive)
                TextButton.icon(
                  key: const Key('open-weekly-schedule'),
                  onPressed: () => context.router.push(
                    GroupScheduleRoute(groupId: group.id),
                  ),
                  icon: const Icon(Icons.event_repeat),
                  label: Text(LocaleKeys.classes_weekly_schedule.tr()),
                ),
            ],
          ),
          if (!group.isActive) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              message: LocaleKeys.classes_archived_notice.tr(),
              tone: TelmizoMessageTone.info,
            ),
          ],
        ],
      ),
    );
  }
}
