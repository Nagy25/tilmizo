import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Active/inactive switch card from the Stitch group forms.
class ActiveToggleTile extends StatelessWidget {
  const ActiveToggleTile({
    super.key,
    required this.notifier,
    required this.enabled,
  });

  final ValueNotifier<bool> notifier;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isActive, _) => Material(
        color: TelmizoColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: TelmizoRadius.lgAll,
          side: BorderSide(color: TelmizoColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          key: const Key('group-active'),
          value: isActive,
          onChanged: enabled ? (value) => notifier.value = value : null,
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: TelmizoSpacing.md,
            vertical: TelmizoSpacing.sm,
          ),
          secondary: CircleAvatar(
            backgroundColor: TelmizoColors.primaryTint,
            foregroundColor: TelmizoColors.primary,
            child: Icon(isActive ? Icons.bolt : Icons.pause_circle_outline),
          ),
          title: Text(
            LocaleKeys.group_active_label.tr(),
            style: context.textTheme.titleMedium,
          ),
          subtitle: Text(
            LocaleKeys.group_active_body.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
