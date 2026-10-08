import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../controllers/homework_providers.dart';

/// Entry to a group's homework with a live count.
class HomeworkHomeTile extends ConsumerWidget {
  const HomeworkHomeTile({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(groupHomeworkProvider(groupId));
    final subtitle = switch (homework) {
      AsyncData(:final value) when value.isNotEmpty =>
        LocaleKeys.homework_count.plural(value.length),
      _ => LocaleKeys.homework_tile_subtitle.tr(),
    };
    return TelmizoCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const Key('homework-tile'),
          onTap: () =>
              context.router.push(GroupHomeworkRoute(groupId: groupId)),
          minTileHeight: 72,
          leading: const CircleAvatar(
            backgroundColor: TelmizoColors.primaryTint,
            foregroundColor: TelmizoColors.primary,
            child: Icon(Icons.assignment_outlined),
          ),
          title: Text(LocaleKeys.homework_title.tr()),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
