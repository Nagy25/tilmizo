import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../../../profile/presentation/controllers/resource_storage_usage_controller.dart';
import '../widgets/resource_type_sheet.dart';
import '../widgets/resources_list_view.dart';

@RoutePage()
class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final limits = ref.read(resourceStorageUsageProvider).value?.uploadLimits;
    final type = await showResourceTypeSheet(context, limits: limits);
    if (type == null || !context.mounted) return;
    await context.router.push(
      AddResourceRoute(groupId: groupId, type: type.backendValue),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupDetailsProvider(groupId));
    final canManage = group.value?.isActive ?? false;
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.resources_title.tr(),
        subtitle: group.value?.name,
        showBack: true,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              key: const Key('add-resource'),
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add),
              label: Text(LocaleKeys.resources_add.tr()),
            )
          : null,
      body: group.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) {
          final type = failureTypeOf(error);
          return TelmizoErrorView(
            icon: type == AppFailureType.notFound
                ? Icons.search_off
                : Icons.cloud_off_outlined,
            title: type == AppFailureType.notFound
                ? LocaleKeys.group_not_found_title.tr()
                : LocaleKeys.groups_load_error_title.tr(),
            message: appFailureMessage(type),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(groupDetailsProvider(groupId)),
          );
        },
        data: (TeacherGroup group) =>
            ResourcesListView(group: group, onAdd: () => _add(context, ref)),
      ),
    );
  }
}
