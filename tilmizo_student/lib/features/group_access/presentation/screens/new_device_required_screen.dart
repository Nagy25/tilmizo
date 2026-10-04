import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/student_access_state.dart';
import '../widgets/access_status_hero.dart';
import '../widgets/device_replacement_panel.dart';
import '../widgets/group_state_gate.dart';
import '../widgets/group_summary_card.dart';
import '../widgets/status_screen_scaffold.dart';

/// The student is a member, but this device/session is not approved.
@RoutePage()
class NewDeviceRequiredScreen extends StatelessWidget {
  const NewDeviceRequiredScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return StatusScreenScaffold(
      subtitle: LocaleKeys.new_device_title.tr(),
      body: GroupStateGate(
        groupId: groupId,
        expected: StudentAccessState.newDeviceRequired,
        builder: (context, entry) => TelmizoScrollBody(
          children: [
            AccessStatusHero(
              icon: Icons.phonelink_setup_outlined,
              badge: LocaleKeys.new_device_badge.tr(),
              title: LocaleKeys.new_device_title.tr(),
              body: LocaleKeys.new_device_body.tr(),
              tone: TelmizoMessageTone.info,
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            GroupSummaryCard(
              name: entry.groupName,
              subject: entry.subject,
              grade: entry.grade,
              teacherName: entry.teacherName,
            ),
            const SizedBox(height: TelmizoSpacing.md),
            DeviceReplacementPanel(
              entry: entry,
              submitLabel: LocaleKeys.new_device_submit.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
