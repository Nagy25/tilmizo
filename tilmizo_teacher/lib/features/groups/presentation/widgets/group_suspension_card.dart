import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/teacher_group.dart';

/// Suspend or resume control for an active group. Suspension is separate
/// from archiving: it pauses new sessions and amounts only.
class GroupSuspensionCard extends StatelessWidget {
  const GroupSuspensionCard({
    super.key,
    required this.group,
    required this.onToggle,
    this.isBusy = false,
    this.isLoading = false,
  });

  final TeacherGroup group;
  final VoidCallback onToggle;
  final bool isBusy;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final suspended = group.isSuspended;
    return TelmizoCard(
      key: const Key('group-suspension-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                suspended ? Icons.pause_circle : Icons.pause_circle_outline,
                color: TelmizoColors.tertiary,
              ),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Text(
                  LocaleKeys.group_suspension_title.tr(),
                  style: context.textTheme.titleMedium,
                ),
              ),
              if (suspended)
                TelmizoPill(
                  label: LocaleKeys.group_status_suspended.tr(),
                  background: TelmizoColors.tertiaryContainer,
                  foreground: TelmizoColors.onTertiaryContainer,
                ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            suspended
                ? LocaleKeys.group_suspension_suspended_body.tr()
                : LocaleKeys.group_suspension_active_body.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          TelmizoSecondaryButton(
            key: const Key('group-suspension-toggle'),
            label: suspended
                ? LocaleKeys.group_resume_action.tr()
                : LocaleKeys.group_suspend_action.tr(),
            icon: suspended ? Icons.play_circle_outline : Icons.pause,
            isLoading: isLoading,
            onPressed: isBusy ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

/// Confirms suspending ([suspend] true) or resuming a group.
Future<bool> confirmGroupSuspension(
  BuildContext context, {
  required bool suspend,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        suspend
            ? LocaleKeys.group_suspend_confirm_title.tr()
            : LocaleKeys.group_resume_confirm_title.tr(),
      ),
      content: Text(
        suspend
            ? LocaleKeys.group_suspend_confirm_body.tr()
            : LocaleKeys.group_resume_confirm_body.tr(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(LocaleKeys.common_cancel.tr()),
        ),
        TextButton(
          key: const Key('confirm-group-suspension'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            suspend
                ? LocaleKeys.group_suspend_confirm.tr()
                : LocaleKeys.group_resume_confirm.tr(),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
