import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../../domain/classes_repository.dart';
import '../controllers/classes_providers.dart';
import '../widgets/add_classes_flow.dart';
import '../widgets/classes_filters.dart';
import '../widgets/classes_group_header.dart';
import '../widgets/scheduling_tips_card.dart';
import '../widgets/sessions_list_section.dart';

/// Upcoming, past, and cancelled sessions of one group, or of every group
/// when [groupId] is null.
@RoutePage()
class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key, @QueryParam('groupId') this.groupId});

  final String? groupId;

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  SessionsView _view = SessionsView.upcoming;
  String? _filterGroupId;

  String? get _groupId => widget.groupId ?? _filterGroupId;

  Future<void> _refresh() async {
    final groupId = _groupId;
    ref.invalidate(nextSessionProvider);
    if (groupId != null) ref.invalidate(groupMembersProvider(groupId));
    await Future.wait([
      ref
          .read(sessionsListProvider((groupId: groupId, view: _view)).notifier)
          .refresh(),
      ref.read(groupsControllerProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsControllerProvider);
    return Scaffold(
      appBar: AppHeader(title: LocaleKeys.classes_title.tr(), showBack: true),
      body: groups.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) => TelmizoErrorView(
          title: LocaleKeys.classes_load_error_title.tr(),
          message: appFailureMessage(failureTypeOf(error)),
          retryLabel: LocaleKeys.common_retry.tr(),
          onRetry: () => ref.invalidate(groupsControllerProvider),
        ),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(List<TeacherGroup> groups) {
    final groupId = _groupId;
    final group = groups.where((g) => g.id == groupId).firstOrNull;
    if (widget.groupId != null && group == null) {
      return TelmizoErrorView(
        icon: Icons.search_off,
        title: LocaleKeys.group_not_found_title.tr(),
        message: LocaleKeys.group_not_found_body.tr(),
        retryLabel: LocaleKeys.common_back.tr(),
        onRetry: () => context.router.maybePop(),
      );
    }
    final activeGroups = groups.where((g) => g.isActive).toList();
    final canAdd = group == null ? activeGroups.isNotEmpty : group.isActive;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          TelmizoSpacing.lg,
          TelmizoSpacing.margin,
          TelmizoSpacing.xl,
        ),
        children: [
          if (widget.groupId == null && groups.length > 1) ...[
            GroupFilterChips(
              groups: groups,
              selectedId: _filterGroupId,
              onChanged: (id) => setState(() => _filterGroupId = id),
            ),
            const SizedBox(height: TelmizoSpacing.md),
          ],
          if (group != null) ...[
            ClassesGroupHeader(group: group),
            const SizedBox(height: TelmizoSpacing.md),
          ],
          if (canAdd) ...[
            TelmizoPrimaryButton(
              key: const Key('add-classes'),
              label: LocaleKeys.classes_add.tr(),
              icon: Icons.add_circle_outline,
              onPressed: () => startAddClasses(
                context,
                groupId: group?.id,
                activeGroups: activeGroups,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.lg),
          ],
          SessionsViewTabs(
            selected: _view,
            onChanged: (view) => setState(() => _view = view),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          SessionsListSection(query: (groupId: groupId, view: _view)),
          const SizedBox(height: TelmizoSpacing.lg),
          const SchedulingTipsCard(),
        ],
      ),
    );
  }
}
