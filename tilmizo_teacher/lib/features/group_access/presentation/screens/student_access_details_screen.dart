import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/group_member.dart';
import '../controllers/group_access_action_controller.dart';
import '../controllers/group_access_providers.dart';
import '../widgets/access_labels.dart';
import '../widgets/access_pills.dart';
import '../widgets/confirm_access_dialog.dart';
import '../widgets/device_card.dart';
import '../widgets/group_access_live_scope.dart';
import '../widgets/student_identity_card.dart';

@RoutePage()
class StudentAccessDetailsScreen extends ConsumerWidget {
  const StudentAccessDetailsScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
    @PathParam('membershipId') required this.membershipId,
  });

  final String groupId;
  final String membershipId;

  Future<void> _suspend(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    final confirmed = await confirmAccessAction(
      context,
      title: LocaleKeys.access_suspend_confirm_title.tr(),
      body: LocaleKeys.access_suspend_confirm_body.tr(
        args: [studentDisplayName(member.studentName)],
      ),
      confirmLabel: LocaleKeys.access_suspend_confirm.tr(),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final suspended = await ref
        .read(groupAccessActionControllerProvider.notifier)
        .suspend(member);
    if (suspended && context.mounted) {
      showTelmizoSnackBar(context, LocaleKeys.access_suspended_success.tr());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(groupMemberDetailsProvider(membershipId));
    final action = ref.watch(groupAccessActionControllerProvider);

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.access_student_details_title.tr(),
        showBack: true,
      ),
      body: GroupAccessLiveScope(
        groupId: groupId,
        child: member.when(
          skipLoadingOnRefresh: true,
          loading: () => const TelmizoLoadingView(),
          error: (error, _) {
            final type = failureTypeOf(error);
            final missing = type == AppFailureType.notFound;
            return TelmizoErrorView(
              icon: missing
                  ? Icons.person_off_outlined
                  : Icons.cloud_off_outlined,
              title: missing
                  ? LocaleKeys.access_member_unavailable_title.tr()
                  : LocaleKeys.access_load_error_title.tr(),
              message: missing
                  ? LocaleKeys.access_member_unavailable.tr()
                  : appFailureMessage(type),
              retryLabel: missing
                  ? LocaleKeys.access_back_to_list.tr()
                  : LocaleKeys.common_retry.tr(),
              onRetry: missing
                  ? () => context.router.maybePop()
                  : () => ref.invalidate(
                      groupMemberDetailsProvider(membershipId),
                    ),
            );
          },
          data: (member) => TelmizoScrollBody(
            children: [
              StudentIdentityCard(
                name: member.studentName,
                phone: member.studentPhone,
                trailing: MemberStatusPill(status: member.status),
                caption: LocaleKeys.access_joined_on.tr(
                  args: [accessDate(context, member.joinedAt)],
                ),
              ),
              const SizedBox(height: TelmizoSpacing.lg),
              DeviceCard(
                title: LocaleKeys.access_approved_device.tr(),
                device: member.approvedDevice,
              ),
              if (!member.isActive) ...[
                const SizedBox(height: TelmizoSpacing.lg),
                TelmizoInlineMessage(
                  message: LocaleKeys.access_suspended_note.tr(),
                  tone: TelmizoMessageTone.info,
                ),
              ],
              if (action.failure case final failure?) ...[
                const SizedBox(height: TelmizoSpacing.md),
                TelmizoInlineMessage(
                  message: failure == AppFailureType.rejected
                      ? LocaleKeys.access_member_unavailable.tr()
                      : appFailureMessage(failure),
                ),
              ],
              if (member.isActive) ...[
                const SizedBox(height: TelmizoSpacing.xl),
                SizedBox(
                  height: TelmizoSpacing.buttonHeight,
                  child: TextButton.icon(
                    onPressed: action.isBusy
                        ? null
                        : () => _suspend(context, ref, member),
                    style: TextButton.styleFrom(
                      foregroundColor: TelmizoColors.error,
                    ),
                    icon: action.inProgress == GroupAccessAction.suspend
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block),
                    label: Text(LocaleKeys.access_suspend.tr()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
