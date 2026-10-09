import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../announcements/presentation/controllers/student_announcements_providers.dart';
import '../../../announcements/presentation/widgets/student_announcements_tab.dart';
import '../../../homework/presentation/controllers/student_homework_providers.dart';
import '../../../homework/presentation/widgets/student_homework_tab.dart';
import '../../../payments/presentation/controllers/student_payments_providers.dart';
import '../../../payments/presentation/widgets/student_payments_view.dart';
import '../../../resources/presentation/controllers/student_resources_providers.dart';
import '../../../resources/presentation/widgets/student_resources_tab.dart';
import '../../../student_classes/presentation/controllers/student_classes_providers.dart';
import '../../../student_classes/presentation/widgets/student_group_schedule_section.dart';
import '../../../student_classes/presentation/widgets/student_group_sessions_section.dart';
import '../../domain/approved_group.dart';
import '../../domain/group_access_entry.dart';
import '../controllers/group_access_providers.dart';
import 'approved_group_info_tab.dart';
import 'approved_group_tab_list.dart';

/// The approved-group tabs, in display order. [name] is the `tab` query
/// value of the approved-group route.
enum ApprovedGroupTab {
  info,
  classes,
  homework,
  announcements,
  resources,
  payments;

  static ApprovedGroupTab parse(String? value) =>
      values.where((tab) => tab.name == value).firstOrNull ?? info;
}

/// Info, Classes, Homework, Announcements, Resources and Payments tabs for
/// an approved group.
class ApprovedGroupTabs extends ConsumerStatefulWidget {
  const ApprovedGroupTabs({
    super.key,
    required this.group,
    required this.entry,
    this.initialTab = ApprovedGroupTab.info,
  });

  final ApprovedGroup group;
  final GroupAccessEntry entry;
  final ApprovedGroupTab initialTab;

  @override
  ConsumerState<ApprovedGroupTabs> createState() => _ApprovedGroupTabsState();
}

class _ApprovedGroupTabsState extends ConsumerState<ApprovedGroupTabs>
    with SingleTickerProviderStateMixin {
  static final _homeworkTab = ApprovedGroupTab.homework.index;
  static final _announcementsTab = ApprovedGroupTab.announcements.index;
  static final _resourcesTab = ApprovedGroupTab.resources.index;
  static final _paymentsTab = ApprovedGroupTab.payments.index;

  late final _tabs = TabController(
    length: ApprovedGroupTab.values.length,
    vsync: this,
    initialIndex: widget.initialTab.index,
  )..addListener(_onTabChanged);

  late final AppLifecycleListener _lifecycle;

  String get _groupId => widget.group.id;

  @override
  void initState() {
    super.initState();
    // Homework, announcements, resources and payments are not in Supabase
    // Realtime; reload them on app resume.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        refreshStudentHomework(ref, _groupId);
        refreshStudentAnnouncements(ref, _groupId);
        refreshStudentResources(ref, _groupId);
        refreshStudentPayments(ref, _groupId);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index == _homeworkTab) refreshStudentHomework(ref, _groupId);
    if (_tabs.index == _announcementsTab) {
      refreshStudentAnnouncements(ref, _groupId);
    }
    if (_tabs.index == _resourcesTab) refreshStudentResources(ref, _groupId);
    if (_tabs.index == _paymentsTab) refreshStudentPayments(ref, _groupId);
  }

  Future<void> _refresh() async {
    await ref.read(groupAccessOverviewProvider.notifier).refresh();
    ref.invalidate(approvedGroupProvider(_groupId));
    refreshStudentClasses(ref);
    refreshStudentHomework(ref, _groupId);
    refreshStudentAnnouncements(ref, _groupId);
    refreshStudentResources(ref, _groupId);
    refreshStudentPayments(ref, _groupId);
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(studentResourceCountsProvider(_groupId)).value;
    final total = counts?.values.fold(0, (sum, count) => sum + count);
    return Column(
      children: [
        // Scrollable so six Arabic labels and the badge fit narrow RTL
        // phones without truncation.
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              key: const Key('group-tab-info'),
              text: LocaleKeys.group_tab_info.tr(),
            ),
            Tab(
              key: const Key('group-tab-classes'),
              text: LocaleKeys.group_tab_classes.tr(),
            ),
            Tab(
              key: const Key('group-tab-homework'),
              text: LocaleKeys.group_tab_homework.tr(),
            ),
            Tab(
              key: const Key('group-tab-announcements'),
              text: LocaleKeys.group_tab_announcements.tr(),
            ),
            Tab(
              key: const Key('group-tab-resources'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LocaleKeys.group_tab_resources.tr()),
                  if (total != null && total > 0) ...[
                    const SizedBox(width: TelmizoSpacing.xs),
                    Badge.count(
                      count: total,
                      backgroundColor: TelmizoColors.primary,
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              key: const Key('group-tab-payments'),
              text: LocaleKeys.group_tab_payments.tr(),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ApprovedGroupInfoTab(
                group: widget.group,
                entry: widget.entry,
                onRefresh: _refresh,
              ),
              ApprovedGroupTabList(
                onRefresh: _refresh,
                children: [
                  StudentGroupScheduleSection(groupId: _groupId),
                  const SizedBox(height: TelmizoSpacing.lg),
                  StudentGroupSessionsSection(groupId: _groupId),
                ],
              ),
              StudentHomeworkTab(groupId: _groupId, onRefresh: _refresh),
              StudentAnnouncementsTab(groupId: _groupId, onRefresh: _refresh),
              StudentResourcesTab(groupId: _groupId, onRefresh: _refresh),
              StudentPaymentsView(groupId: _groupId, onRefresh: _refresh),
            ],
          ),
        ),
      ],
    );
  }
}
