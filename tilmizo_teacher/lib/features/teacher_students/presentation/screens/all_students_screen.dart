import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/teacher_student.dart';
import '../controllers/teacher_students_provider.dart';
import '../widgets/all_students_filters.dart';
import '../widgets/teacher_student_card.dart';

@RoutePage()
class AllStudentsScreen extends ConsumerStatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  ConsumerState<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends ConsumerState<AllStudentsScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _groupId = '';
  MembershipStatus? _status;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeacherStudent> _filtered(List<TeacherStudent> students) {
    final query = _search.trim().toLowerCase();
    final phoneDigits = query.replaceAll(RegExp(r'\D'), '');
    return students
        .where((student) {
          final memberships = student.memberships.where(
            (membership) =>
                (_groupId.isEmpty || membership.groupId == _groupId) &&
                (_status == null || membership.status == _status),
          );
          if (memberships.isEmpty) return false;
          return query.isEmpty ||
              (student.name?.toLowerCase().contains(query) ?? false) ||
              (phoneDigits.isNotEmpty &&
                  student.phone
                      .replaceAll(RegExp(r'\D'), '')
                      .contains(phoneDigits)) ||
              memberships.any(
                (membership) =>
                    membership.groupName.toLowerCase().contains(query),
              );
        })
        .toList(growable: false);
  }

  Map<String, String> _groups(List<TeacherStudent> students) {
    final groups = <String, String>{};
    for (final student in students) {
      for (final membership in student.memberships) {
        groups[membership.groupId] = membership.groupName;
      }
    }
    final entries = groups.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return Map.fromEntries(entries);
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(teacherStudentsProvider);
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.all_students_title.tr(),
        showBack: true,
      ),
      body: students.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) => TelmizoErrorView(
          title: LocaleKeys.all_students_load_error.tr(),
          message: appFailureMessage(failureTypeOf(error)),
          retryLabel: LocaleKeys.common_retry.tr(),
          onRetry: () => ref.invalidate(teacherStudentsProvider),
        ),
        data: (students) {
          final filtered = _filtered(students);
          final groups = _groups(students);
          final visibleGroupId = groups.containsKey(_groupId) ? _groupId : '';
          final multiGroupCount = students
              .where((student) => student.groupCount > 1)
              .length;
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(teacherStudentsProvider.future).then((_) {}),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(TelmizoSpacing.margin),
              itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StudentsSummary(
                        count: students.length,
                        multiGroupCount: multiGroupCount,
                      ),
                      const SizedBox(height: TelmizoSpacing.lg),
                      AllStudentsFilters(
                        searchController: _searchController,
                        groups: groups,
                        groupId: visibleGroupId,
                        status: _status,
                        onSearchChanged: (value) =>
                            setState(() => _search = value),
                        onGroupChanged: (value) =>
                            setState(() => _groupId = value),
                        onStatusChanged: (value) =>
                            setState(() => _status = value),
                      ),
                      const SizedBox(height: TelmizoSpacing.lg),
                    ],
                  );
                }
                if (filtered.isEmpty) {
                  return TelmizoCard(
                    child: Text(
                      students.isEmpty
                          ? LocaleKeys.all_students_empty.tr()
                          : LocaleKeys.all_students_no_matches.tr(),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: TelmizoSpacing.md),
                  child: TeacherStudentCard(student: filtered[index - 1]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StudentsSummary extends StatelessWidget {
  const _StudentsSummary({required this.count, required this.multiGroupCount});

  final int count;
  final int multiGroupCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(TelmizoSpacing.lg),
    decoration: const BoxDecoration(
      color: TelmizoColors.primary,
      borderRadius: TelmizoRadius.xlAll,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.all_students_count.tr(args: ['$count']),
          style: context.textTheme.headlineMedium?.copyWith(
            color: TelmizoColors.onPrimary,
          ),
        ),
        Text(
          LocaleKeys.all_students_multi_group.tr(args: ['$multiGroupCount']),
          style: context.textTheme.bodyMedium?.copyWith(
            color: TelmizoColors.onPrimary,
          ),
        ),
      ],
    ),
  );
}
