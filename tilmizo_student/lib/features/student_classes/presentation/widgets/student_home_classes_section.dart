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

class StudentHomeClassesSection extends ConsumerWidget {
  const StudentHomeClassesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(
      studentSessionsPageProvider((
        view: StudentSessionsView.upcoming,
        groupId: null,
        offset: 0,
        limit: 3,
      )),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                LocaleKeys.classes_upcoming_title.tr(),
                style: context.textTheme.headlineSmall,
              ),
            ),
            TextButton(
              onPressed: () => context.router.push(StudentClassesRoute()),
              child: Text(LocaleKeys.classes_view_all.tr()),
            ),
          ],
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        page.when(
          loading: () => const TelmizoLoadingView(),
          error: (_, _) =>
              TelmizoInlineMessage(message: LocaleKeys.classes_load_error.tr()),
          data: (result) => result.sessions.isEmpty
              ? TelmizoCard(child: Text(LocaleKeys.classes_no_upcoming.tr()))
              : Column(
                  children: [
                    for (final session in result.sessions)
                      StudentSessionCard(
                        session: session,
                        onTap: () => context.router.push(
                          StudentSessionDetailsRoute(sessionId: session.id),
                        ),
                      ),
                    if (result.total case final count?)
                      Text(
                        LocaleKeys.classes_upcoming_count.tr(args: ['$count']),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
