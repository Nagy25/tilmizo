import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../domain/class_session.dart';
import '../controllers/classes_providers.dart';
import '../formatting/session_formatting.dart';

/// Entry to the classes list with a live summary of the next session.
class ClassesHomeTile extends ConsumerWidget {
  const ClassesHomeTile({super.key, this.groupId});

  /// Limits the list and summary to one group; null covers all groups.
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextSessionProvider(groupId));
    final subtitle = switch (next) {
      AsyncData(value: final session?) => _nextLabel(context, session),
      AsyncData() => LocaleKeys.classes_home_no_upcoming.tr(),
      AsyncError() => LocaleKeys.classes_home_error.tr(),
      _ => LocaleKeys.classes_home_loading.tr(),
    };
    return TelmizoCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          key: const Key('classes-tile'),
          onTap: () {
            ref.invalidate(nextSessionProvider(groupId));
            context.router.push(ClassesRoute(groupId: groupId));
          },
          minTileHeight: 72,
          leading: const CircleAvatar(
            backgroundColor: TelmizoColors.primaryTint,
            foregroundColor: TelmizoColors.primary,
            child: Icon(Icons.event_available_outlined),
          ),
          title: Text(LocaleKeys.classes_title.tr()),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  String _nextLabel(BuildContext context, ClassSession session) {
    final when =
        '${context.cairoShortDate(session.startsAt)} • '
        '${context.cairoTime(session.startsAt)}';
    return groupId == null
        ? LocaleKeys.classes_home_next_with_group.tr(
            args: [session.group.name, when],
          )
        : LocaleKeys.classes_home_next.tr(args: [when]);
  }
}
