import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/group_access_entry.dart';
import '../../domain/student_access_state.dart';

/// One group on the home screen with its access state and next action.
class GroupAccessCard extends StatelessWidget {
  const GroupAccessCard({super.key, required this.entry, required this.onTap});

  final GroupAccessEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final approved = entry.state == StudentAccessState.approved;
    final details = [
      entry.subject,
      entry.grade,
    ].whereType<String>().join(' • ');

    return TelmizoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: TelmizoSpacing.sm,
            runSpacing: TelmizoSpacing.xs,
            children: [
              _StatePill(state: entry.state),
              if (entry.grade case final grade?)
                TelmizoPill(
                  label: grade,
                  background: TelmizoColors.surfaceContainerLow,
                  foreground: TelmizoColors.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.md),
          Text(entry.groupName, style: textTheme.titleLarge),
          if (entry.teacherName case final teacher?)
            Text(
              LocaleKeys.teacher_label.tr(args: [teacher]),
              style: textTheme.bodySmall?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
          if (details.isNotEmpty && entry.grade == null)
            Text(details, style: textTheme.bodySmall),
          if (approved && entry.approvedDeviceName != null) ...[
            const SizedBox(height: TelmizoSpacing.md),
            Container(
              padding: const EdgeInsets.all(TelmizoSpacing.md),
              decoration: const BoxDecoration(
                color: TelmizoColors.surfaceContainerLow,
                borderRadius: TelmizoRadius.mdAll,
              ),
              child: Row(
                children: [
                  const Icon(Icons.smartphone, size: 18),
                  const SizedBox(width: TelmizoSpacing.sm),
                  Expanded(
                    child: Text(
                      '${entry.approvedDeviceName} ${LocaleKeys.this_device.tr()}',
                      style: textTheme.bodySmall?.copyWith(
                        color: TelmizoColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: TelmizoSpacing.md),
          Semantics(
            label: LocaleKeys.open_group_semantics.tr(args: [entry.groupName]),
            excludeSemantics: true,
            button: true,
            child: TelmizoSecondaryButton(
              label: approved
                  ? LocaleKeys.card_open.tr()
                  : LocaleKeys.card_view_status.tr(),
              icon: Icons.arrow_forward,
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.state});

  final StudentAccessState state;

  @override
  Widget build(BuildContext context) {
    final (label, icon, background, foreground) = switch (state) {
      StudentAccessState.approved => (
        LocaleKeys.state_approved,
        Icons.check_circle_outline,
        TelmizoColors.successContainer,
        TelmizoColors.success,
      ),
      StudentAccessState.pendingJoin => (
        LocaleKeys.state_pending,
        Icons.hourglass_top,
        TelmizoColors.tertiaryContainer,
        TelmizoColors.onTertiaryContainer,
      ),
      StudentAccessState.replacementPending => (
        LocaleKeys.state_replacement_pending,
        Icons.hourglass_top,
        TelmizoColors.tertiaryContainer,
        TelmizoColors.onTertiaryContainer,
      ),
      StudentAccessState.newDeviceRequired => (
        LocaleKeys.state_new_device,
        Icons.phonelink_setup_outlined,
        TelmizoColors.secondaryContainer,
        TelmizoColors.onSecondaryContainer,
      ),
      StudentAccessState.accessReplaced => (
        LocaleKeys.state_replaced,
        Icons.phonelink_erase_outlined,
        TelmizoColors.errorContainer,
        TelmizoColors.onErrorContainer,
      ),
      StudentAccessState.rejected => (
        LocaleKeys.state_rejected,
        Icons.block,
        TelmizoColors.errorContainer,
        TelmizoColors.onErrorContainer,
      ),
      StudentAccessState.accessRemoved => (
        LocaleKeys.state_removed,
        Icons.person_off_outlined,
        TelmizoColors.errorContainer,
        TelmizoColors.onErrorContainer,
      ),
    };
    return TelmizoPill(
      label: label.tr(),
      icon: icon,
      background: background,
      foreground: foreground,
    );
  }
}
