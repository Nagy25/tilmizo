import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/group_access_entry.dart';
import '../../domain/student_access_state.dart';
import '../controllers/group_access_providers.dart';
import '../controllers/membership_action_controller.dart';
import '../widgets/access_status_hero.dart';
import '../widgets/device_info_card.dart';
import '../widgets/group_state_gate.dart';
import '../widgets/group_summary_card.dart';
import '../widgets/status_screen_scaffold.dart';
import '../../../student_classes/presentation/controllers/student_classes_providers.dart';
import '../../../student_classes/presentation/widgets/student_classes_refresh_scope.dart';
import '../../../student_classes/presentation/widgets/student_group_schedule_section.dart';
import '../../../student_classes/presentation/widgets/student_group_sessions_section.dart';

/// Minimal approved-group summary. Group details come from the
/// session-bound `groups` RLS; if RLS stops returning the group, cached data
/// is dropped and the access flow is resolved again.
@RoutePage()
class ApprovedGroupScreen extends ConsumerWidget {
  const ApprovedGroupScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    GroupAccessEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.leave_confirm_title.tr()),
        content: Text(
          LocaleKeys.leave_confirm_body.tr(args: [entry.groupName]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocaleKeys.common_cancel.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: TelmizoColors.error),
            child: Text(LocaleKeys.leave_confirm.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final left = await ref
        .read(membershipActionControllerProvider.notifier)
        .leave(entry);
    if (left && context.mounted) {
      showTelmizoSnackBar(context, LocaleKeys.leave_success.tr());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access lost on the backend: refresh the overview so the gate moves to
    // the replaced, removed, or new-device screen.
    ref.listen(approvedGroupProvider(groupId), (_, next) {
      if (next.error case AppFailure(type: AppFailureType.notFound)) {
        ref.invalidate(groupAccessOverviewProvider);
      }
    });

    return StatusScreenScaffold(
      subtitle: LocaleKeys.approved_title.tr(),
      body: StudentClassesRefreshScope(
        child: GroupStateGate(
          groupId: groupId,
          expected: StudentAccessState.approved,
          builder: (context, entry) {
            final group = ref.watch(approvedGroupProvider(groupId));
            final action = ref.watch(membershipActionControllerProvider);
            return group.when(
              loading: () => const TelmizoLoadingView(),
              error: (error, _) => TelmizoErrorView(
                title: LocaleKeys.group_unavailable_title.tr(),
                message: failureTypeOf(error) == AppFailureType.notFound
                    ? LocaleKeys.group_unavailable_body.tr()
                    : appFailureMessage(failureTypeOf(error)),
                retryLabel: LocaleKeys.common_retry.tr(),
                onRetry: () => ref.invalidate(groupAccessOverviewProvider),
              ),
              data: (group) => RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(groupAccessOverviewProvider.notifier)
                      .refresh();
                  ref.invalidate(approvedGroupProvider(groupId));
                  refreshStudentClasses(ref);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    TelmizoSpacing.margin,
                    TelmizoSpacing.lg,
                    TelmizoSpacing.margin,
                    TelmizoSpacing.xl,
                  ),
                  children: [
                    AccessStatusHero(
                      icon: group.isActive
                          ? Icons.verified_outlined
                          : Icons.archive_outlined,
                      badge: group.isActive
                          ? LocaleKeys.approved_badge.tr()
                          : LocaleKeys.group_archived.tr(),
                      title: group.isActive
                          ? LocaleKeys.approved_title.tr()
                          : LocaleKeys.group_archived.tr(),
                      body: group.isActive
                          ? LocaleKeys.approved_body.tr()
                          : LocaleKeys.group_archived_body.tr(),
                      tone: group.isActive
                          ? TelmizoMessageTone.success
                          : TelmizoMessageTone.info,
                    ),
                    const SizedBox(height: TelmizoSpacing.lg),
                    GroupSummaryCard(
                      name: group.name,
                      subject: group.subject,
                      grade: group.grade,
                      teacherName: entry.teacherName,
                    ),
                    if (group.isActive && group.inviteCode != null) ...[
                      const SizedBox(height: TelmizoSpacing.md),
                      TelmizoCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(LocaleKeys.group_invite_code.tr()),
                                  SelectableText(group.inviteCode!),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: LocaleKeys.group_copy_code.tr(),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: group.inviteCode!),
                                );
                                if (context.mounted) {
                                  showTelmizoSnackBar(
                                    context,
                                    LocaleKeys.group_code_copied.tr(),
                                  );
                                }
                              },
                              icon: const Icon(Icons.copy_outlined),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (entry.approvedDeviceName case final device?) ...[
                      const SizedBox(height: TelmizoSpacing.md),
                      DeviceInfoCard(
                        label: LocaleKeys.approved_device_label.tr(),
                        deviceName: device,
                        isThisDevice: true,
                      ),
                    ],
                    const SizedBox(height: TelmizoSpacing.lg),
                    StudentGroupScheduleSection(groupId: groupId),
                    const SizedBox(height: TelmizoSpacing.lg),
                    StudentGroupSessionsSection(groupId: groupId),
                    if (action.failure case final failure?) ...[
                      const SizedBox(height: TelmizoSpacing.md),
                      TelmizoInlineMessage(message: appFailureMessage(failure)),
                    ],
                    const SizedBox(height: TelmizoSpacing.xl),
                    SizedBox(
                      height: TelmizoSpacing.buttonHeight,
                      child: TextButton.icon(
                        onPressed: action.isBusy || entry.membershipId == null
                            ? null
                            : () => _leave(context, ref, entry),
                        style: TextButton.styleFrom(
                          foregroundColor: TelmizoColors.error,
                        ),
                        icon: action.inProgress == MembershipAction.leave
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout),
                        label: Text(LocaleKeys.leave_group.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
