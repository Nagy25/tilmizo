import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/teacher_avatar.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../profile/presentation/controllers/current_profile_controller.dart';

/// Groups top bar with profile access.
class GroupsAppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const GroupsAppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    return AppHeader(
      title: LocaleKeys.app_name.tr(),
      subtitle: LocaleKeys.groups_header_subtitle.tr(),
      trailing: Tooltip(
        message: LocaleKeys.groups_profile_button.tr(),
        child: Semantics(
          button: true,
          label: LocaleKeys.groups_profile_button.tr(),
          child: InkResponse(
            onTap: () => context.router.push(const EditProfileRoute()),
            radius: 28,
            child: SizedBox.square(
              dimension: 52,
              child: Center(
                child: TeacherAvatar(avatarUrl: profile?.avatarUrl, size: 44),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
