import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../classes/domain/class_session.dart';
import '../controllers/homework_providers.dart';
import 'homework_card.dart';

/// The session's homework on the session-details page, with the entry point
/// for adding homework to this session.
class SessionHomeworkCard extends ConsumerWidget {
  const SessionHomeworkCard({super.key, required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(sessionHomeworkProvider(session.id));
    final textTheme = context.textTheme;
    return TelmizoCard(
      key: const Key('session-homework-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: TelmizoColors.primary,
              ),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Text(
                  LocaleKeys.session_homework_title.tr(),
                  style: textTheme.titleMedium,
                ),
              ),
              if (homework is AsyncError)
                IconButton(
                  tooltip: LocaleKeys.common_retry.tr(),
                  onPressed: () =>
                      ref.invalidate(sessionHomeworkProvider(session.id)),
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          ...switch (homework) {
            AsyncData(:final value) when value.isEmpty => [
              Text(LocaleKeys.session_homework_none.tr()),
            ],
            AsyncData(:final value) => [
              for (final item in value) ...[
                const SizedBox(height: TelmizoSpacing.sm),
                HomeworkCard(
                  homework: item,
                  onTap: () => context.router.push(
                    HomeworkDetailsRoute(homeworkId: item.id),
                  ),
                ),
              ],
            ],
            AsyncError() => [Text(LocaleKeys.session_homework_load_error.tr())],
            _ => [const LinearProgressIndicator()],
          },
          if (session.canAddHomework) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoSecondaryButton(
              key: const Key('add-homework'),
              label: LocaleKeys.homework_add.tr(),
              icon: Icons.add,
              onPressed: () =>
                  context.router.push(AddHomeworkRoute(sessionId: session.id)),
            ),
          ],
        ],
      ),
    );
  }
}
