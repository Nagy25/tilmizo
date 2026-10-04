import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/student_access_state.dart';
import '../controllers/group_access_providers.dart';
import '../widgets/access_status_hero.dart';
import '../widgets/device_info_card.dart';
import '../widgets/group_state_gate.dart';
import '../widgets/group_summary_card.dart';
import '../widgets/join_steps_progress.dart';
import '../widgets/status_actions.dart';
import '../widgets/status_screen_scaffold.dart';

/// An initial join request waiting for the teacher. No group content is
/// shown before approval.
@RoutePage()
class PendingRequestScreen extends ConsumerWidget {
  const PendingRequestScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thisDevice = ref.watch(deviceDisplayInfoProvider).value;
    return StatusScreenScaffold(
      subtitle: LocaleKeys.pending_title.tr(),
      body: GroupStateGate(
        groupId: groupId,
        expected: StudentAccessState.pendingJoin,
        builder: (context, entry) => TelmizoScrollBody(
          children: [
            AccessStatusHero(
              icon: Icons.hourglass_top,
              badge: LocaleKeys.pending_badge.tr(),
              title: LocaleKeys.pending_title.tr(),
              body: LocaleKeys.pending_body.tr(),
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            GroupSummaryCard(
              name: entry.groupName,
              subject: entry.subject,
              grade: entry.grade,
              teacherName: entry.teacherName,
            ),
            // The request came from this session, so the teacher sees this
            // device's name.
            if (thisDevice != null && entry.requestFromCurrentSession) ...[
              const SizedBox(height: TelmizoSpacing.md),
              DeviceInfoCard(
                label: LocaleKeys.device_sent_label.tr(),
                deviceName: thisDevice.name,
                platform: thisDevice.platform,
                isThisDevice: true,
              ),
            ],
            const SizedBox(height: TelmizoSpacing.lg),
            const JoinStepsProgress(currentStep: 2),
            const SizedBox(height: TelmizoSpacing.xl),
            const StatusRefreshActions(),
          ],
        ),
      ),
    );
  }
}
