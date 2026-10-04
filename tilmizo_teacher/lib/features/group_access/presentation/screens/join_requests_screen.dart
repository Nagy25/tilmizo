import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../controllers/group_access_providers.dart';
import '../widgets/access_empty_view.dart';
import '../widgets/access_labels.dart';
import '../widgets/access_list_card.dart';
import '../widgets/access_pills.dart';
import '../widgets/group_access_live_scope.dart';

@RoutePage()
class JoinRequestsScreen extends ConsumerWidget {
  const JoinRequestsScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingJoinRequestsProvider(groupId));
    Future<void> reload() =>
        ref.refresh(pendingJoinRequestsProvider(groupId).future);

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.access_requests_title.tr(),
        showBack: true,
      ),
      body: GroupAccessLiveScope(
        groupId: groupId,
        child: requests.when(
          skipLoadingOnRefresh: true,
          loading: () => const TelmizoLoadingView(),
          error: (error, _) => TelmizoErrorView(
            title: LocaleKeys.access_load_error_title.tr(),
            message: appFailureMessage(failureTypeOf(error)),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(pendingJoinRequestsProvider(groupId)),
          ),
          data: (requests) => RefreshIndicator(
            onRefresh: reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(TelmizoSpacing.margin),
              itemCount: requests.isEmpty ? 1 : requests.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: TelmizoSpacing.md),
              itemBuilder: (context, index) {
                if (requests.isEmpty) {
                  return AccessEmptyView(
                    icon: Icons.inbox_outlined,
                    title: LocaleKeys.access_requests_empty_title.tr(),
                    body: LocaleKeys.access_requests_empty_body.tr(),
                  );
                }
                final request = requests[index];
                return AccessListCard(
                  name: request.studentName,
                  phone: request.studentPhone,
                  semanticLabel: LocaleKeys.access_open_request_semantics.tr(
                    args: [studentDisplayName(request.studentName)],
                  ),
                  pill: RequestTypePill(type: request.type),
                  detail:
                      '${request.device.name} • '
                      '${platformLabel(request.device.platform)}',
                  onTap: () => context.router.push(
                    JoinRequestDetailsRoute(
                      groupId: groupId,
                      requestId: request.id,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
