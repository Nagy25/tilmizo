import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../groups/domain/teacher_group.dart';
import 'group_picker_sheet.dart';
import 'schedule_type_sheet.dart';

/// Starts adding a weekly schedule or one-time session. When [groupId] is
/// null the teacher first picks one of [activeGroups].
Future<void> startAddClasses(
  BuildContext context, {
  String? groupId,
  List<TeacherGroup> activeGroups = const [],
}) async {
  var targetId = groupId;
  if (targetId == null) {
    if (activeGroups.isEmpty) {
      showTelmizoSnackBar(context, LocaleKeys.classes_no_active_groups.tr());
      return;
    }
    final group = activeGroups.length == 1
        ? activeGroups.single
        : await showGroupPickerSheet(context, activeGroups);
    if (group == null || !context.mounted) return;
    targetId = group.id;
  }
  final type = await showScheduleTypeSheet(context);
  if (type == null || !context.mounted) return;
  await context.router.push(switch (type) {
    ScheduleType.weekly => WeeklyScheduleFormRoute(groupId: targetId),
    ScheduleType.oneTime => OneTimeSessionRoute(groupId: targetId),
  });
}
