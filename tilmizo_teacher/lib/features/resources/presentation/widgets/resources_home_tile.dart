import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../controllers/resources_providers.dart';

/// Entry to a group's resources with a live resource count.
class ResourcesHomeTile extends ConsumerWidget {
  const ResourcesHomeTile({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(resourceTypeCountsProvider(groupId));
    final subtitle = switch (counts) {
      AsyncData(:final value) when value.isNotEmpty =>
        LocaleKeys.resources_count.plural(
          value.values.fold(0, (sum, count) => sum + count),
        ),
      _ => LocaleKeys.resources_tile_subtitle.tr(),
    };
    return TelmizoCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const Key('resources-tile'),
          onTap: () => context.router.push(ResourcesRoute(groupId: groupId)),
          minTileHeight: 72,
          leading: const CircleAvatar(
            backgroundColor: TelmizoColors.primaryTint,
            foregroundColor: TelmizoColors.primary,
            child: Icon(Icons.folder_open_outlined),
          ),
          title: Text(LocaleKeys.resources_title.tr()),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
