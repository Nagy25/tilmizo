import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../announcement_labels.dart';

/// Publication date with an edited mark, shared by the card and details.
class AnnouncementMeta extends StatelessWidget {
  const AnnouncementMeta({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: TelmizoSpacing.sm,
    runSpacing: TelmizoSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule,
            size: 16,
            color: TelmizoColors.onSurfaceVariant,
          ),
          const SizedBox(width: TelmizoSpacing.xs),
          Text(
            context.announcementPublished(announcement),
            style: context.textTheme.labelMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      if (announcement.isEdited)
        TelmizoPill(
          icon: Icons.edit_outlined,
          label: LocaleKeys.announcements_edited.tr(),
          background: TelmizoColors.surfaceContainerLow,
          foreground: TelmizoColors.onSurfaceVariant,
        ),
    ],
  );
}
