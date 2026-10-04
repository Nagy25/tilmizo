import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../controllers/group_access_providers.dart';

/// Group-details entry points to join requests (with a pending badge) and
/// the student list.
class GroupAccessEntryCard extends ConsumerWidget {
  const GroupAccessEntryCard({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingJoinRequestsProvider(groupId)).value;
    return TelmizoCard(
      padding: const EdgeInsets.symmetric(vertical: TelmizoSpacing.sm),
      // ListTile ink needs a Material between it and the card's decoration.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TelmizoSpacing.lg,
                TelmizoSpacing.md,
                TelmizoSpacing.lg,
                TelmizoSpacing.xs,
              ),
              child: Text(
                LocaleKeys.access_section_title.tr(),
                style: context.textTheme.headlineSmall,
              ),
            ),
            _EntryTile(
              icon: Icons.how_to_reg_outlined,
              title: LocaleKeys.access_requests_title.tr(),
              body: LocaleKeys.access_requests_body.tr(),
              badgeCount: pending?.length ?? 0,
              onTap: () =>
                  context.router.push(JoinRequestsRoute(groupId: groupId)),
            ),
            const Divider(
              indent: TelmizoSpacing.lg,
              endIndent: TelmizoSpacing.lg,
            ),
            _EntryTile(
              icon: Icons.groups_outlined,
              title: LocaleKeys.access_students_title.tr(),
              body: LocaleKeys.access_students_body.tr(),
              badgeCount: 0,
              onTap: () =>
                  context.router.push(GroupStudentsRoute(groupId: groupId)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: TelmizoSpacing.lg),
      leading: CircleAvatar(
        backgroundColor: TelmizoColors.primaryTint,
        foregroundColor: TelmizoColors.primary,
        child: Icon(icon),
      ),
      title: Text(title, style: context.textTheme.titleMedium),
      subtitle: Text(
        body,
        style: context.textTheme.bodySmall?.copyWith(
          color: TelmizoColors.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount > 0)
            Semantics(
              label: LocaleKeys.access_pending_count.tr(args: ['$badgeCount']),
              excludeSemantics: true,
              child: Badge.count(
                count: badgeCount,
                backgroundColor: TelmizoColors.error,
              ),
            ),
          const Icon(Icons.chevron_left),
        ],
      ),
    );
  }
}
