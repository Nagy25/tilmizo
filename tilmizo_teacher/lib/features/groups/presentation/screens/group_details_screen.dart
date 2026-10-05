import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../controllers/groups_controller.dart';
import '../widgets/group_details_view.dart';

@RoutePage()
class GroupDetailsScreen extends ConsumerWidget {
  const GroupDetailsScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  /// Returns to whichever groups screen matches the refreshed list.
  Future<void> _returnToGroups(BuildContext context, WidgetRef ref) async {
    final router = context.router;
    var hasGroups = true;
    try {
      await ref.read(groupsControllerProvider.notifier).refresh();
      hasGroups = ref.read(groupsControllerProvider).value?.isNotEmpty ?? true;
    } on AppFailure {
      // Fall back to the dashboard, which offers its own retry.
    }
    await router.replaceAll([
      hasGroups ? const GroupsDashboardRoute() : const EmptyGroupsRoute(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupDetailsProvider(groupId));

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.group_details_title.tr(),
        subtitle: group.value?.name,
        showBack: true,
        onBack: () => context.router.canPop()
            ? context.router.pop()
            : _returnToGroups(context, ref),
      ),
      body: group.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) {
          final type = failureTypeOf(error);
          if (type == AppFailureType.notFound) {
            return TelmizoErrorView(
              icon: Icons.search_off,
              title: LocaleKeys.group_not_found_title.tr(),
              message: LocaleKeys.group_not_found_body.tr(),
              retryLabel: LocaleKeys.back_to_groups.tr(),
              onRetry: () => _returnToGroups(context, ref),
            );
          }
          return TelmizoErrorView(
            title: LocaleKeys.groups_load_error_title.tr(),
            message: appFailureMessage(type),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(groupDetailsProvider(groupId)),
          );
        },
        data: (group) => GroupDetailsView(
          key: ValueKey(group.id),
          group: group,
          onEdit: () => context.router.push(EditGroupRoute(groupId: group.id)),
        ),
      ),
    );
  }
}
