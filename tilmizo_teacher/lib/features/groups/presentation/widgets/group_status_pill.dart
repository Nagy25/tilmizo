import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

class GroupStatusPill extends StatelessWidget {
  const GroupStatusPill({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return isActive
        ? TelmizoPill(
            label: LocaleKeys.group_status_active.tr(),
            icon: Icons.circle,
            background: TelmizoColors.successContainer,
            foreground: TelmizoColors.success,
          )
        : TelmizoPill(
            label: LocaleKeys.group_status_inactive.tr(),
            icon: Icons.lock_outline,
            background: TelmizoColors.secondaryContainer,
            foreground: TelmizoColors.onSecondaryContainer,
          );
  }
}
