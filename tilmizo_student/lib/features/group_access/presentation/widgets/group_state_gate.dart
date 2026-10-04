import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../../router/student_destination_route.dart';
import '../../domain/group_access_entry.dart';
import '../../domain/student_access_state.dart';
import '../controllers/group_access_providers.dart';
import 'student_access_live_scope.dart';

/// Shows a group status screen only while the backend reports [expected].
/// When the state changes (approval, replacement, suspension, ...) it
/// replaces itself with the matching screen.
class GroupStateGate extends ConsumerStatefulWidget {
  const GroupStateGate({
    super.key,
    required this.groupId,
    required this.expected,
    required this.builder,
  });

  final String groupId;
  final StudentAccessState expected;
  final Widget Function(BuildContext context, GroupAccessEntry entry) builder;

  @override
  ConsumerState<GroupStateGate> createState() => _GroupStateGateState();
}

class _GroupStateGateState extends ConsumerState<GroupStateGate> {
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<List<GroupAccessEntry>>>(
      groupAccessOverviewProvider,
      (_, next) => _follow(next),
      fireImmediately: true,
    );
  }

  void _follow(AsyncValue<List<GroupAccessEntry>> overview) {
    final entries = overview.value;
    if (entries == null || _navigating || !mounted) return;
    final entry = findEntry(entries, widget.groupId);
    if (entry != null && entry.state == widget.expected) return;

    _navigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = context.router;
      if (entry == null) {
        router.replaceAll([
          entries.isEmpty ? const EmptyGroupsRoute() : const GroupsHomeRoute(),
        ]);
      } else {
        router.replace(accessStateRoute(entry));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(groupAccessOverviewProvider);
    return StudentAccessLiveScope(
      child: overview.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) => TelmizoErrorView(
          title: LocaleKeys.status_load_error_title.tr(),
          message: appFailureMessage(failureTypeOf(error)),
          retryLabel: LocaleKeys.common_retry.tr(),
          onRetry: () => ref.invalidate(groupAccessOverviewProvider),
        ),
        data: (entries) {
          final entry = findEntry(entries, widget.groupId);
          if (entry == null || entry.state != widget.expected) {
            return const TelmizoLoadingView();
          }
          return widget.builder(context, entry);
        },
      ),
    );
  }
}
