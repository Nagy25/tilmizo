import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/student_access_state.dart';
import '../controllers/group_access_providers.dart';
import '../widgets/approved_group_tabs.dart';
import '../widgets/group_state_gate.dart';
import '../widgets/status_screen_scaffold.dart';
import '../../../student_classes/presentation/widgets/student_classes_refresh_scope.dart';

/// Approved-group Info, Classes, Resources and Payments tabs. Group details come from
/// the session-bound `groups` RLS; if RLS stops returning the group, cached
/// data is dropped and the access flow is resolved again.
@RoutePage()
class ApprovedGroupScreen extends ConsumerWidget {
  const ApprovedGroupScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
    @QueryParam('tab') this.tab,
  });

  final String groupId;

  /// An [ApprovedGroupTab] name to open first, for example from a
  /// notification.
  final String? tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access lost on the backend: refresh the overview so the gate moves to
    // the replaced, removed, or new-device screen.
    ref.listen(approvedGroupProvider(groupId), (_, next) {
      if (next.error case AppFailure(type: AppFailureType.notFound)) {
        ref.invalidate(groupAccessOverviewProvider);
      }
    });

    return StatusScreenScaffold(
      subtitle: LocaleKeys.approved_title.tr(),
      body: StudentClassesRefreshScope(
        child: GroupStateGate(
          groupId: groupId,
          expected: StudentAccessState.approved,
          builder: (context, entry) => ref
              .watch(approvedGroupProvider(groupId))
              .when(
                loading: () => const TelmizoLoadingView(),
                error: (error, _) => TelmizoErrorView(
                  title: LocaleKeys.group_unavailable_title.tr(),
                  message: failureTypeOf(error) == AppFailureType.notFound
                      ? LocaleKeys.group_unavailable_body.tr()
                      : appFailureMessage(failureTypeOf(error)),
                  retryLabel: LocaleKeys.common_retry.tr(),
                  onRetry: () => ref.invalidate(groupAccessOverviewProvider),
                ),
                data: (group) => ApprovedGroupTabs(
                  group: group,
                  entry: entry,
                  initialTab: ApprovedGroupTab.parse(tab),
                ),
              ),
        ),
      ),
    );
  }
}
