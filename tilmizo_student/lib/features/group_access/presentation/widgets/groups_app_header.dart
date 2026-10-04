import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../profile/presentation/widgets/account_sheet.dart';

/// Groups top bar with access to the account sheet (logout).
class GroupsAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const GroupsAppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      title: LocaleKeys.app_name.tr(),
      subtitle: LocaleKeys.home_header_subtitle.tr(),
      trailing: IconButton(
        tooltip: LocaleKeys.account_button.tr(),
        onPressed: () => showAccountSheet(context),
        style: IconButton.styleFrom(
          backgroundColor: TelmizoColors.primary,
          foregroundColor: TelmizoColors.onPrimary,
        ),
        icon: const Icon(Icons.person_outline),
      ),
    );
  }
}
