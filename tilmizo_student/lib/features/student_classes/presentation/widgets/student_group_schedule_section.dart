import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/student_class.dart';
import '../controllers/student_classes_providers.dart';
import '../formatting/student_class_formatting.dart';

class StudentGroupScheduleSection extends ConsumerWidget {
  const StudentGroupScheduleSection({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(studentScheduleProvider(groupId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.schedule_weekly_title.tr(),
          style: context.textTheme.headlineSmall,
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        entries.when(
          loading: () => const TelmizoLoadingView(),
          error: (_, _) => Text(LocaleKeys.schedule_load_error.tr()),
          data: (rows) {
            if (rows.isEmpty) return Text(LocaleKeys.schedule_empty.tr());
            final sorted = [...rows]
              ..sort(
                (a, b) => ((a.weekday + 1) % 7).compareTo((b.weekday + 1) % 7),
              );
            return Column(
              children: [
                for (final entry in sorted) _ScheduleCard(entry: entry),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.entry});

  final StudentScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    final location = entry.locationType == SessionLocationType.physical
        ? entry.physicalLocation
        : LocaleKeys.session_online.tr();
    return Padding(
      padding: const EdgeInsets.only(bottom: TelmizoSpacing.sm),
      child: TelmizoCard(
        child: Row(
          children: [
            Icon(
              entry.locationType == SessionLocationType.online
                  ? Icons.videocam_outlined
                  : Icons.location_on_outlined,
              color: TelmizoColors.primary,
            ),
            const SizedBox(width: TelmizoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekdayLabel(entry.weekday),
                    style: context.textTheme.titleMedium,
                  ),
                  Text(scheduleTimeRange(context, entry)),
                  if (location != null)
                    Text(location, style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
