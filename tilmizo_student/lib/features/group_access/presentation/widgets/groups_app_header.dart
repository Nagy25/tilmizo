import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../notifications/presentation/widgets/notifications_bell.dart';
import '../../../profile/presentation/widgets/account_sheet.dart';
import '../../../profile/presentation/controllers/current_profile_controller.dart';

/// Groups top bar with the notification bell and the account sheet
/// (logout).
class GroupsAppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const GroupsAppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    return AppHeader(
      title: LocaleKeys.app_name.tr(),
      subtitle: LocaleKeys.home_header_subtitle.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NotificationsBell(),
          const SizedBox(width: TelmizoSpacing.xs),
          Tooltip(
            message: LocaleKeys.account_button.tr(),
            child: InkResponse(
              onTap: () => showAccountSheet(context),
              radius: 28,
              child: SizedBox.square(
                dimension: 52,
                child: Center(
                  child: TelmizoAvatar(
                    avatarUrl: profile?.avatarUrl,
                    fullName: profile?.fullName,
                    avatarRevision: profile?.updatedAt
                        ?.toUtc()
                        .toIso8601String(),
                    size: 44,
                    semanticLabel: LocaleKeys.account_button.tr(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
