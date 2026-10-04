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
class GroupStudentsScreen extends ConsumerWidget {
  const GroupStudentsScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.access_students_title.tr(),
        showBack: true,
      ),
      body: GroupAccessLiveScope(
        groupId: groupId,
        child: members.when(
          skipLoadingOnRefresh: true,
          loading: () => const TelmizoLoadingView(),
          error: (error, _) => TelmizoErrorView(
            title: LocaleKeys.access_load_error_title.tr(),
            message: appFailureMessage(failureTypeOf(error)),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
          ),
          data: (members) => RefreshIndicator(
            onRefresh: () => ref.refresh(groupMembersProvider(groupId).future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(TelmizoSpacing.margin),
              itemCount: members.isEmpty ? 1 : members.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: TelmizoSpacing.md),
              itemBuilder: (context, index) {
                if (members.isEmpty) {
                  return AccessEmptyView(
                    icon: Icons.groups_outlined,
                    title: LocaleKeys.access_students_empty_title.tr(),
                    body: LocaleKeys.access_students_empty_body.tr(),
                  );
                }
                final member = members[index];
                final device = member.approvedDevice;
                return AccessListCard(
                  name: member.studentName,
                  phone: member.studentPhone,
                  semanticLabel: LocaleKeys.access_open_student_semantics.tr(
                    args: [studentDisplayName(member.studentName)],
                  ),
                  pill: MemberStatusPill(status: member.status),
                  detail: device == null
                      ? LocaleKeys.access_no_approved_device.tr()
                      : '${device.name} • ${platformLabel(device.platform)}',
                  onTap: () => context.router.push(
                    StudentAccessDetailsRoute(
                      groupId: groupId,
                      membershipId: member.membershipId,
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
