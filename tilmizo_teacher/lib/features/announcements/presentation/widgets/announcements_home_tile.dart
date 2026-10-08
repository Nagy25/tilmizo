import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../announcement_labels.dart';
import '../controllers/announcements_providers.dart';

/// Entry to a group's announcements with the latest publication date.
class AnnouncementsHomeTile extends ConsumerWidget {
  const AnnouncementsHomeTile({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(announcementsFeedProvider(groupId));
    final subtitle = switch (feed) {
      AsyncData(:final value) when value.announcements.isNotEmpty =>
        LocaleKeys.announcements_tile_latest.tr(
          args: [context.announcementDate(value.announcements.first.createdAt)],
        ),
      _ => LocaleKeys.announcements_tile_subtitle.tr(),
    };
    return TelmizoCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const Key('announcements-tile'),
          onTap: () =>
              context.router.push(AnnouncementsRoute(groupId: groupId)),
          minTileHeight: 72,
          leading: const CircleAvatar(
            backgroundColor: TelmizoColors.secondaryContainer,
            foregroundColor: TelmizoColors.onSecondaryContainer,
            child: Icon(Icons.campaign_outlined),
          ),
          title: Text(LocaleKeys.announcements_title.tr()),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
