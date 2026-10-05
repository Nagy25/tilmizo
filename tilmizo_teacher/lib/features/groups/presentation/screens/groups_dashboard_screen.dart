import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../domain/teacher_group.dart';
import '../controllers/groups_controller.dart';
import '../widgets/group_card.dart';
import '../widgets/classes_placeholder_tile.dart';
import '../widgets/groups_app_header.dart';
import '../widgets/groups_summary_card.dart';
import '../widgets/teacher_greeting.dart';
import '../../../teacher_students/presentation/widgets/all_students_home_tile.dart';
import '../../../teacher_students/presentation/controllers/teacher_students_provider.dart';

@RoutePage()
class GroupsDashboardScreen extends ConsumerStatefulWidget {
  const GroupsDashboardScreen({super.key});

  @override
  ConsumerState<GroupsDashboardScreen> createState() =>
      _GroupsDashboardScreenState();
}

class _GroupsDashboardScreenState extends ConsumerState<GroupsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Groups removed elsewhere can leave the list empty after a refresh.
    ref.listenManual<AsyncValue<List<TeacherGroup>>>(groupsControllerProvider, (
      _,
      next,
    ) {
      if (next case AsyncData(value: final groups)
          when groups.isEmpty && mounted) {
        context.router.replaceAll([const EmptyGroupsRoute()]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsControllerProvider);
    final notifier = ref.read(groupsControllerProvider.notifier);

    return Scaffold(
      appBar: const GroupsAppHeader(),
      body: groups.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) => TelmizoErrorView(
          title: LocaleKeys.groups_load_error_title.tr(),
          message: appFailureMessage(failureTypeOf(error)),
          retryLabel: LocaleKeys.common_retry.tr(),
          onRetry: notifier.refresh,
        ),
        data: (groups) => RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              notifier.refresh(),
              ref.refresh(teacherStudentsProvider.future).then((_) {}),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              TelmizoSpacing.margin,
              TelmizoSpacing.lg,
              TelmizoSpacing.margin,
              TelmizoSpacing.xl,
            ),
            children: [
              const TeacherGreeting(),
              const SizedBox(height: TelmizoSpacing.lg),
              GroupsSummaryCard(groups: groups),
              const SizedBox(height: TelmizoSpacing.md),
              const AllStudentsHomeTile(),

              const SizedBox(height: TelmizoSpacing.md),
              const ClassesPlaceholderTile(),
              for (final group in groups) ...[
                const SizedBox(height: TelmizoSpacing.md),
                GroupCard(
                  group: group,
                  onTap: () =>
                      context.router.push(GroupDetailsRoute(groupId: group.id)),
                ),
              ],
              const SizedBox(height: TelmizoSpacing.lg),
              TelmizoPrimaryButton(
                label: LocaleKeys.create_group.tr(),
                icon: Icons.add_circle_outline,
                onPressed: () => context.router.push(const CreateGroupRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
