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
import '../widgets/status_actions.dart';
import '../widgets/status_screen_scaffold.dart';

/// This device asked to replace the approved one; the previous device keeps
/// access until the teacher approves.
@RoutePage()
class ReplacementPendingScreen extends ConsumerWidget {
  const ReplacementPendingScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thisDevice = ref.watch(deviceDisplayInfoProvider).value;
    return StatusScreenScaffold(
      subtitle: LocaleKeys.replacement_title.tr(),
      body: GroupStateGate(
        groupId: groupId,
        expected: StudentAccessState.replacementPending,
        builder: (context, entry) => TelmizoScrollBody(
          children: [
            AccessStatusHero(
              icon: Icons.sync_lock_outlined,
              badge: LocaleKeys.replacement_badge.tr(),
              title: LocaleKeys.replacement_title.tr(),
              body: LocaleKeys.replacement_body.tr(),
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            GroupSummaryCard(
              name: entry.groupName,
              subject: entry.subject,
              grade: entry.grade,
              teacherName: entry.teacherName,
            ),
            if (entry.approvedDeviceName case final current?) ...[
              const SizedBox(height: TelmizoSpacing.md),
              DeviceInfoCard(
                label: LocaleKeys.current_device_label.tr(),
                deviceName: current,
              ),
            ],
            if (thisDevice != null) ...[
              const SizedBox(height: TelmizoSpacing.md),
              DeviceInfoCard(
                label: LocaleKeys.device_sent_label.tr(),
                deviceName: thisDevice.name,
                platform: thisDevice.platform,
                isThisDevice: true,
              ),
            ],
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              message: LocaleKeys.keep_previous_note.tr(),
              tone: TelmizoMessageTone.info,
            ),
            const SizedBox(height: TelmizoSpacing.xl),
            const StatusRefreshActions(),
          ],
        ),
      ),
    );
  }
}
