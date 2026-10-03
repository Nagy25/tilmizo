import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/teacher_avatar.dart';
import '../../../../generated/locale_keys.g.dart';

/// Optional avatar display. Uploading is unavailable in Phase 1, so this card
/// is informational and noninteractive.
class AvatarCard extends StatelessWidget {
  const AvatarCard({super.key, this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoCard(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      child: Row(
        children: [
          TeacherAvatar(
            avatarUrl: avatarUrl,
            size: 64,
            semanticLabel: LocaleKeys.profile_avatar_semantics.tr(),
          ),
          const SizedBox(width: TelmizoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.profile_avatar_title.tr(),
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: TelmizoSpacing.xs),
                Text(
                  LocaleKeys.profile_avatar_body.tr(),
                  style: textTheme.bodySmall?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
