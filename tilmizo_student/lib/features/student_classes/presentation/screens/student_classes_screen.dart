import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../group_access/domain/student_access_state.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../domain/student_class.dart';
import '../controllers/student_classes_providers.dart';
import '../widgets/student_classes_refresh_scope.dart';
import '../widgets/student_session_card.dart';

@RoutePage()
class StudentClassesScreen extends ConsumerStatefulWidget {
  const StudentClassesScreen({super.key, this.groupId});

  final String? groupId;

  @override
  ConsumerState<StudentClassesScreen> createState() =>
      _StudentClassesScreenState();
}

class _StudentClassesScreenState extends ConsumerState<StudentClassesScreen> {
  static const _pageSize = 20;

  StudentSessionsView _view = StudentSessionsView.upcoming;
  String? _groupId;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _groupId = widget.groupId;
  }

  Future<void> _refresh() async {
    await ref.read(groupAccessOverviewProvider.notifier).refresh();
    refreshStudentClasses(ref);
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(groupAccessOverviewProvider);
    final approved = [
      for (final entry in overview.value ?? [])
        if (entry.state == StudentAccessState.approved) entry,
    ];
    final selected = approved.any((e) => e.groupId == _groupId)
        ? _groupId
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.classes_title.tr())),
      body: StudentClassesRefreshScope(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(TelmizoSpacing.margin),
            children: [
              if (overview.hasError)
                Text(LocaleKeys.classes_load_error.tr())
              else if (overview.isLoading && overview.value == null)
                const TelmizoLoadingView()
              else ...[
                DropdownButtonFormField<String>(
                  key: ValueKey(selected),
                  initialValue: selected ?? '',
                  decoration: InputDecoration(
                    labelText: LocaleKeys.classes_group_filter.tr(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(LocaleKeys.classes_all_groups.tr()),
                    ),
                    for (final entry in approved)
                      DropdownMenuItem(
                        value: entry.groupId,
                        child: Text(entry.groupName),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _groupId = value == null || value.isEmpty ? null : value;
                    _pages = 1;
                  }),
                ),
                const SizedBox(height: TelmizoSpacing.md),
                Wrap(
                  spacing: TelmizoSpacing.sm,
                  children: [
                    for (final view in StudentSessionsView.values)
                      ChoiceChip(
                        label: Text(_viewLabel(view)),
                        selected: _view == view,
                        onSelected: (_) => setState(() {
                          _view = view;
                          _pages = 1;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                for (var index = 0; index < _pages; index++)
                  _PageSection(
                    request: (
                      view: _view,
                      groupId: selected,
                      offset: index * _pageSize,
                      limit: _pageSize,
                    ),
                    first: index == 0,
                    last: index == _pages - 1,
                    onLoadMore: () => setState(() => _pages++),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _viewLabel(StudentSessionsView view) => switch (view) {
    StudentSessionsView.upcoming => LocaleKeys.classes_upcoming_title.tr(),
    StudentSessionsView.past => LocaleKeys.classes_past_title.tr(),
    StudentSessionsView.cancelled => LocaleKeys.classes_cancelled_title.tr(),
  };
}

class _PageSection extends ConsumerWidget {
  const _PageSection({
    required this.request,
    required this.first,
    required this.last,
    required this.onLoadMore,
  });

  final StudentPageRequest request;
  final bool first;
  final bool last;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(studentSessionsPageProvider(request));
    return page.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(TelmizoSpacing.lg),
        child: TelmizoLoadingView(),
      ),
      error: (_, _) => Column(
        children: [
          Text(LocaleKeys.classes_load_error.tr()),
          TextButton(
            onPressed: () =>
                ref.invalidate(studentSessionsPageProvider(request)),
            child: Text(LocaleKeys.common_retry.tr()),
          ),
        ],
      ),
      data: (result) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (first && result.total != null)
            Padding(
              padding: const EdgeInsets.only(bottom: TelmizoSpacing.md),
              child: Text(
                LocaleKeys.classes_count.tr(args: ['${result.total}']),
              ),
            ),
          if (first && result.sessions.isEmpty)
            TelmizoCard(child: Text(LocaleKeys.classes_empty_view.tr())),
          for (final session in result.sessions)
            StudentSessionCard(
              session: session,
              showAttendance: request.view == StudentSessionsView.past,
              onTap: () => context.router.push(
                StudentSessionDetailsRoute(sessionId: session.id),
              ),
            ),
          if (last && result.hasMore)
            TextButton(
              onPressed: onLoadMore,
              child: Text(LocaleKeys.classes_load_more.tr()),
            ),
        ],
      ),
    );
  }
}
