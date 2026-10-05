import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../widgets/groups_app_header.dart';
import '../widgets/classes_placeholder_tile.dart';
import '../widgets/teacher_greeting.dart';
import '../../../teacher_students/presentation/widgets/all_students_home_tile.dart';

/// Dedicated first-run screen when the teacher owns no groups.
@RoutePage()
class EmptyGroupsScreen extends StatelessWidget {
  const EmptyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Scaffold(
      appBar: const GroupsAppHeader(),
      body: TelmizoScrollBody(
        children: [
          const TeacherGreeting(),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoCard(
            padding: const EdgeInsets.all(TelmizoSpacing.xl),
            child: Column(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: const BoxDecoration(
                    color: TelmizoColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const CircleAvatar(
                    radius: 44,
                    backgroundColor: TelmizoColors.primaryTint,
                    foregroundColor: TelmizoColors.primary,
                    child: Icon(Icons.group_add_outlined, size: 40),
                  ),
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                Text(
                  LocaleKeys.empty_groups_title.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: TelmizoSpacing.sm),
                Text(
                  LocaleKeys.empty_groups_body.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                TelmizoPrimaryButton(
                  label: LocaleKeys.create_group.tr(),
                  icon: Icons.add_circle_outline,
                  onPressed: () =>
                      context.router.push(const CreateGroupRoute()),
                ),
              ],
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          const ClassesPlaceholderTile(),
          const SizedBox(height: TelmizoSpacing.lg),
          const AllStudentsHomeTile(),
        ],
      ),
    );
  }
}
