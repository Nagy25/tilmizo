import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../domain/student_access_state.dart';
import '../widgets/access_status_hero.dart';
import '../widgets/group_state_gate.dart';
import '../widgets/group_summary_card.dart';
import '../widgets/status_actions.dart';
import '../widgets/status_screen_scaffold.dart';

/// Suspended by the teacher or left by the student. No group content.
@RoutePage()
class AccessRemovedScreen extends StatelessWidget {
  const AccessRemovedScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return StatusScreenScaffold(
      subtitle: LocaleKeys.removed_title.tr(),
      body: GroupStateGate(
        groupId: groupId,
        expected: StudentAccessState.accessRemoved,
        builder: (context, entry) => TelmizoScrollBody(
          children: [
            AccessStatusHero(
              icon: Icons.person_off_outlined,
              badge: LocaleKeys.removed_badge.tr(),
              title: LocaleKeys.removed_title.tr(),
              body: LocaleKeys.removed_body.tr(),
              tone: TelmizoMessageTone.error,
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            GroupSummaryCard(
              name: entry.groupName,
              subject: entry.subject,
              grade: entry.grade,
              teacherName: entry.teacherName,
            ),
            const SizedBox(height: TelmizoSpacing.xl),
            StatusRefreshActions(
              primary: TelmizoPrimaryButton(
                label: LocaleKeys.removed_join_again.tr(),
                icon: Icons.vpn_key_outlined,
                onPressed: () => context.router.push(const JoinGroupRoute()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
