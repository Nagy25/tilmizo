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
import '../widgets/group_access_card.dart';
import '../widgets/groups_app_header.dart';
import '../widgets/home_greeting_card.dart';
import '../widgets/join_banner.dart';
import '../widgets/privacy_note_card.dart';
import '../widgets/student_access_live_scope.dart';
import '../../../student_classes/presentation/controllers/student_classes_providers.dart';
import '../../../student_classes/presentation/widgets/student_classes_refresh_scope.dart';
import '../../../student_classes/presentation/widgets/student_home_classes_section.dart';

@RoutePage()
class GroupsHomeScreen extends ConsumerStatefulWidget {
  const GroupsHomeScreen({super.key});

  @override
  ConsumerState<GroupsHomeScreen> createState() => _GroupsHomeScreenState();
}

class _GroupsHomeScreenState extends ConsumerState<GroupsHomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<List<GroupAccessEntry>>>(
      groupAccessOverviewProvider,
      (_, next) {
        if (next case AsyncData(value: final entries)
            when entries.isEmpty && mounted) {
          context.router.replaceAll([const EmptyGroupsRoute()]);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(groupAccessOverviewProvider);
    return Scaffold(
      appBar: const GroupsAppHeader(),
      body: StudentClassesRefreshScope(
        child: StudentAccessLiveScope(
          child: overview.when(
            skipLoadingOnRefresh: true,
            loading: () => const TelmizoLoadingView(),
            error: (error, _) => TelmizoErrorView(
              title: LocaleKeys.status_load_error_title.tr(),
              message: appFailureMessage(failureTypeOf(error)),
              retryLabel: LocaleKeys.common_retry.tr(),
              onRetry: () => ref.invalidate(groupAccessOverviewProvider),
            ),
            data: (entries) => _HomeList(entries: entries),
          ),
        ),
      ),
    );
  }
}

class _HomeList extends ConsumerWidget {
  const _HomeList({required this.entries});

  final List<GroupAccessEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(studentGroupActivityProvider).value;
    final approved = [
      for (final e in entries)
        if (e.state == StudentAccessState.approved) e,
    ];
    final pending = [
      for (final e in entries)
        if (e.state == StudentAccessState.pendingJoin ||
            e.state == StudentAccessState.replacementPending)
          e,
    ];
    final attention = [
      for (final e in entries)
        if (!approved.contains(e) && !pending.contains(e)) e,
    ];

    List<Widget> section(String title, List<GroupAccessEntry> items) => [
      const SizedBox(height: TelmizoSpacing.lg),
      Text(title, style: context.textTheme.headlineSmall),
      for (final entry in items) ...[
        const SizedBox(height: TelmizoSpacing.md),
        GroupAccessCard(
          entry: entry,
          isArchived: activity?[entry.groupId] == false,
          onTap: () => context.router.push(accessStateRoute(entry)),
        ),
      ],
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(groupAccessOverviewProvider.notifier).refresh();
        refreshStudentClasses(ref);
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
          HomeGreetingCard(
            activeGroups: activity == null
                ? null
                : approved.where((e) => activity[e.groupId] == true).length,
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          JoinBanner(onTap: () => context.router.push(const JoinGroupRoute())),
          if (approved.isNotEmpty) ...[
            const SizedBox(height: TelmizoSpacing.lg),
            const StudentHomeClassesSection(),
          ],
          if (approved.isNotEmpty)
            ...section(LocaleKeys.section_my_groups.tr(), approved),
          if (pending.isNotEmpty)
            ...section(LocaleKeys.section_pending.tr(), pending),
          if (attention.isNotEmpty)
            ...section(LocaleKeys.section_attention.tr(), attention),
          const SizedBox(height: TelmizoSpacing.lg),
          const PrivacyNoteCard(),
        ],
      ),
    );
  }
}
