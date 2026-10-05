import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

import '../../domain/teacher_group.dart';
import '../../../group_access/presentation/widgets/group_access_entry_card.dart';
import 'classes_placeholder_tile.dart';
import 'group_overview_card.dart';
import 'invite_code_card.dart';

/// Read-only group details. Editing lives on the dedicated route.
class GroupDetailsView extends StatelessWidget {
  const GroupDetailsView({
    super.key,
    required this.group,
    required this.onEdit,
  });

  final TeacherGroup group;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => TelmizoScrollBody(
    children: [
      GroupOverviewCard(group: group, onEdit: onEdit),
      const SizedBox(height: TelmizoSpacing.lg),
      const ClassesPlaceholderTile(),
      const SizedBox(height: TelmizoSpacing.lg),
      GroupAccessEntryCard(groupId: group.id),
      const SizedBox(height: TelmizoSpacing.lg),
      InviteCodeCard(groupName: group.name, inviteCode: group.inviteCode),
    ],
  );
}
