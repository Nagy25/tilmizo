import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/group_access_entry.dart';
import '../controllers/group_access_providers.dart';
import '../controllers/membership_action_controller.dart';
import 'device_info_card.dart';
import 'status_actions.dart';

/// Current approved device, this device, the "previous device stays active"
/// note, and the replacement request button. Used by the new-device and
/// access-replaced screens; no invite code is needed.
class DeviceReplacementPanel extends ConsumerWidget {
  const DeviceReplacementPanel({
    super.key,
    required this.entry,
    required this.submitLabel,
  });

  final GroupAccessEntry entry;
  final String submitLabel;

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final status = await ref
        .read(membershipActionControllerProvider.notifier)
        .requestReplacement(entry);
    if (status == null || !context.mounted) return;
    // A recognized installation is approved at once; otherwise the gate
    // moves to the replacement-pending screen.
    showTelmizoSnackBar(
      context,
      status == JoinRequestStatus.approved
          ? LocaleKeys.new_device_restored.tr()
          : LocaleKeys.new_device_sent.tr(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(membershipActionControllerProvider);
    final thisDevice = ref.watch(deviceDisplayInfoProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entry.approvedDeviceName case final current?) ...[
          DeviceInfoCard(
            label: LocaleKeys.current_device_label.tr(),
            deviceName: current,
          ),
          const SizedBox(height: TelmizoSpacing.md),
        ],
        if (thisDevice != null) ...[
          DeviceInfoCard(
            label: LocaleKeys.this_device_label.tr(),
            deviceName: thisDevice.name,
            platform: thisDevice.platform,
          ),
          const SizedBox(height: TelmizoSpacing.md),
        ],
        if (entry.replacementRejected) ...[
          TelmizoInlineMessage(
            message: LocaleKeys.new_device_rejected.tr(),
            tone: TelmizoMessageTone.warning,
          ),
          const SizedBox(height: TelmizoSpacing.md),
        ],
        TelmizoInlineMessage(
          message: LocaleKeys.keep_previous_note.tr(),
          tone: TelmizoMessageTone.info,
        ),
        const SizedBox(height: TelmizoSpacing.md),
        TelmizoInlineMessage(
          title: LocaleKeys.join_device_title.tr(),
          message: thisDevice == null
              ? LocaleKeys.join_device_body_unknown.tr()
              : LocaleKeys.join_device_body.tr(args: [thisDevice.name]),
          tone: TelmizoMessageTone.info,
        ),
        const SizedBox(height: TelmizoSpacing.xl),
        StatusRefreshActions(
          primary: TelmizoPrimaryButton(
            label: submitLabel,
            icon: Icons.phonelink_lock_outlined,
            isLoading: action.inProgress == MembershipAction.requestReplacement,
            onPressed:
                action.isBusy ||
                    entry.membershipId == null ||
                    !entry.canRequestDeviceReplacement
                ? null
                : () => _submit(context, ref),
          ),
        ),
      ],
    );
  }
}
