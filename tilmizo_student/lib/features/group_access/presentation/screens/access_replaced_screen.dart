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

/// This device was approved, but the teacher has since approved another one.
@RoutePage()
class AccessReplacedScreen extends StatelessWidget {
  const AccessReplacedScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return StatusScreenScaffold(
      subtitle: LocaleKeys.replaced_title.tr(),
      body: GroupStateGate(
        groupId: groupId,
        expected: StudentAccessState.accessReplaced,
        builder: (context, entry) => TelmizoScrollBody(
          children: [
            AccessStatusHero(
              icon: Icons.phonelink_erase_outlined,
              badge: LocaleKeys.replaced_badge.tr(),
              title: LocaleKeys.replaced_title.tr(),
              body: LocaleKeys.replaced_body.tr(),
              tone: TelmizoMessageTone.error,
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
              submitLabel: LocaleKeys.replaced_request_back.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
