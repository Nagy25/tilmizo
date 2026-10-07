import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/approved_group.dart';
import '../../domain/group_access_entry.dart';
import '../controllers/membership_action_controller.dart';
import 'access_status_hero.dart';
import 'approved_group_tab_list.dart';
import 'device_info_card.dart';
import 'group_summary_card.dart';

/// Group summary, invite code, approved device and the leave action.
class ApprovedGroupInfoTab extends ConsumerWidget {
  const ApprovedGroupInfoTab({
    super.key,
    required this.group,
    required this.entry,
    required this.onRefresh,
  });

  final ApprovedGroup group;
  final GroupAccessEntry entry;
  final Future<void> Function() onRefresh;

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
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
    final action = ref.watch(membershipActionControllerProvider);
    return ApprovedGroupTabList(
      onRefresh: onRefresh,
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
          _InviteCodeCard(code: group.inviteCode!),
        ],
        if (entry.approvedDeviceName case final device?) ...[
          const SizedBox(height: TelmizoSpacing.md),
          DeviceInfoCard(
            label: LocaleKeys.approved_device_label.tr(),
            deviceName: device,
            isThisDevice: true,
          ),
        ],
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
                : () => _leave(context, ref),
            style: TextButton.styleFrom(foregroundColor: TelmizoColors.error),
            icon: action.inProgress == MembershipAction.leave
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(LocaleKeys.leave_group.tr()),
          ),
        ),
      ],
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocaleKeys.group_invite_code.tr()),
              SelectableText(code),
            ],
          ),
        ),
        IconButton(
          tooltip: LocaleKeys.group_copy_code.tr(),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) {
              showTelmizoSnackBar(context, LocaleKeys.group_code_copied.tr());
            }
          },
          icon: const Icon(Icons.copy_outlined),
        ),
      ],
    ),
  );
}
