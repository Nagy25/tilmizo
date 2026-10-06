import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../domain/student_class.dart';
import '../controllers/student_classes_providers.dart';
import 'student_session_card.dart';

class StudentGroupSessionsSection extends ConsumerWidget {
  const StudentGroupSessionsSection({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _GroupSessionList(
        groupId: groupId,
        view: StudentSessionsView.upcoming,
        title: LocaleKeys.classes_upcoming_title.tr(),
      ),
      const SizedBox(height: TelmizoSpacing.lg),
      _GroupSessionList(
        groupId: groupId,
        view: StudentSessionsView.past,
        title: LocaleKeys.classes_past_title.tr(),
      ),
      const SizedBox(height: TelmizoSpacing.md),
      TextButton.icon(
        onPressed: () =>
            context.router.push(StudentClassesRoute(groupId: groupId)),
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(LocaleKeys.classes_view_all.tr()),
      ),
    ],
  );
}

class _GroupSessionList extends ConsumerWidget {
  const _GroupSessionList({
    required this.groupId,
    required this.view,
    required this.title,
  });

  final String groupId;
  final StudentSessionsView view;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(
      studentSessionsPageProvider((
        view: view,
        groupId: groupId,
        offset: 0,
        limit: 3,
      )),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: context.textTheme.headlineSmall),
        const SizedBox(height: TelmizoSpacing.sm),
        page.when(
          loading: () => const TelmizoLoadingView(),
          error: (_, _) => Text(LocaleKeys.classes_load_error.tr()),
          data: (result) => result.sessions.isEmpty
              ? Text(LocaleKeys.classes_empty_view.tr())
              : Column(
                  children: [
                    for (final session in result.sessions)
                      StudentSessionCard(
                        session: session,
                        showAttendance: view == StudentSessionsView.past,
                        onTap: () => context.router.push(
                          StudentSessionDetailsRoute(sessionId: session.id),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
