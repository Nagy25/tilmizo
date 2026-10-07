import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../classes/presentation/widgets/active_group_gate.dart';
import '../controllers/resources_providers.dart';
import '../resource_labels.dart';
import '../widgets/resource_form_view.dart';

/// Edits title, description, session and, for links, the URL.
@RoutePage()
class EditResourceScreen extends ConsumerWidget {
  const EditResourceScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
    @PathParam('resourceId') required this.resourceId,
  });

  final String groupId;
  final String resourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppHeader(
      title: LocaleKeys.resource_form_edit_title.tr(),
      showBack: true,
    ),
    body: ActiveGroupGate(
      groupId: groupId,
      archivedMessage: LocaleKeys.resources_archived_notice.tr(),
      builder: (group) => ref
          .watch(resourceDetailsProvider(resourceId))
          .when(
            skipLoadingOnRefresh: true,
            loading: () => const TelmizoLoadingView(),
            error: (error, _) => TelmizoErrorView(
              title: LocaleKeys.resources_load_error_title.tr(),
              message: resourceFailureMessage(error),
              retryLabel: LocaleKeys.common_retry.tr(),
              onRetry: () =>
                  ref.invalidate(resourceDetailsProvider(resourceId)),
            ),
            data: (resource) => resource.groupId != group.id
                ? TelmizoErrorView(
                    icon: Icons.search_off,
                    title: LocaleKeys.resources_load_error_title.tr(),
                    message: LocaleKeys.resource_error_not_found.tr(),
                    retryLabel: LocaleKeys.common_back.tr(),
                    onRetry: () => context.router.maybePop(),
                  )
                : ResourceFormView(
                    key: ValueKey(resource.id),
                    groupId: group.id,
                    initialType: resource.type,
                    resource: resource,
                  ),
          ),
    ),
  );
}
