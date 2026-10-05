import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../controllers/teacher_students_provider.dart';

class AllStudentsHomeTile extends ConsumerWidget {
  const AllStudentsHomeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(teacherStudentsProvider);
    final count = switch (students) {
      AsyncData(value: final records) => records.length,
      _ => null,
    };
    return TelmizoCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const Key('all-students-tile'),
          onTap: () {
            ref.invalidate(teacherStudentsProvider);
            context.router.push(const AllStudentsRoute());
          },
          minTileHeight: 72,
          leading: const CircleAvatar(
            backgroundColor: TelmizoColors.primaryTint,
            foregroundColor: TelmizoColors.primary,
            child: Icon(Icons.groups_outlined),
          ),
          title: Text(LocaleKeys.all_students_title.tr()),
          subtitle: Text(
            count == null
                ? LocaleKeys.all_students_count_unknown.tr()
                : LocaleKeys.all_students_count.tr(args: ['$count']),
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
