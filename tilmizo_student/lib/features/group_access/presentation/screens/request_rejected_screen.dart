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

@RoutePage()
class RequestRejectedScreen extends StatelessWidget {
  const RequestRejectedScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return StatusScreenScaffold(
      subtitle: LocaleKeys.rejected_title.tr(),
      body: GroupStateGate(
        groupId: groupId,
        expected: StudentAccessState.rejected,
        builder: (context, entry) => TelmizoScrollBody(
          children: [
            AccessStatusHero(
              icon: Icons.block,
              badge: LocaleKeys.state_rejected.tr(),
              title: LocaleKeys.rejected_title.tr(),
              body: LocaleKeys.rejected_body.tr(),
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
                label: LocaleKeys.rejected_try_again.tr(),
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
