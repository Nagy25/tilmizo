import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../groups/domain/teacher_group.dart';

/// Lets the teacher choose which active group to add classes to.
Future<TeacherGroup?> showGroupPickerSheet(
  BuildContext context,
  List<TeacherGroup> groups,
) => showModalBottomSheet<TeacherGroup>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: TelmizoSpacing.lg),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TelmizoSpacing.margin,
          ),
          child: Text(
            LocaleKeys.classes_pick_group_title.tr(),
            style: context.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        for (final group in groups)
          ListTile(
            key: Key('pick-group-${group.id}'),
            leading: const CircleAvatar(
              backgroundColor: TelmizoColors.primaryTint,
              foregroundColor: TelmizoColors.primary,
              child: Icon(Icons.school_outlined),
            ),
            title: Text(group.name),
            subtitle: group.subject == null ? null : Text(group.subject!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pop(group),
          ),
      ],
    ),
  ),
);
