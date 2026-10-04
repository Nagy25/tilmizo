import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

class RequestTypePill extends StatelessWidget {
  const RequestTypePill({super.key, required this.type});

  final JoinRequestType type;

  @override
  Widget build(BuildContext context) => switch (type) {
    JoinRequestType.join => TelmizoPill(
      label: LocaleKeys.access_request_type_join.tr(),
      icon: Icons.person_add_alt_outlined,
      background: TelmizoColors.primaryTint,
      foreground: TelmizoColors.primary,
    ),
    JoinRequestType.deviceReplacement => TelmizoPill(
      label: LocaleKeys.access_request_type_replacement.tr(),
      icon: Icons.sync_alt,
      background: TelmizoColors.tertiaryContainer,
      foreground: TelmizoColors.onTertiaryContainer,
    ),
  };
}

class MemberStatusPill extends StatelessWidget {
  const MemberStatusPill({super.key, required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) => status == MembershipStatus.active
      ? TelmizoPill(
          label: LocaleKeys.access_status_active.tr(),
          icon: Icons.circle,
          background: TelmizoColors.successContainer,
          foreground: TelmizoColors.success,
        )
      : TelmizoPill(
          label: LocaleKeys.access_status_suspended.tr(),
          icon: Icons.block,
          background: TelmizoColors.errorContainer,
          foreground: TelmizoColors.onErrorContainer,
        );
}
