import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../controllers/student_homework_providers.dart';
import 'student_homework_card.dart';

/// The homework of one session on the session page. Opens the same details
/// screen as the group list.
class SessionHomeworkSection extends ConsumerWidget {
  const SessionHomeworkSection({
    super.key,
    required this.groupId,
    required this.sessionId,
  });

  final String groupId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (groupId: groupId, id: sessionId);
    final homework = ref.watch(studentSessionHomeworkProvider(key));
    return TelmizoCard(
      key: const Key('student-session-homework'),
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
                  style: context.textTheme.titleMedium,
                ),
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
                StudentHomeworkCard(
                  homework: item,
                  onTap: () => context.router.push(
                    StudentHomeworkDetailsRoute(
                      groupId: groupId,
                      homeworkId: item.id,
                    ),
                  ),
                ),
              ],
            ],
            AsyncError() => [
              Text(LocaleKeys.session_homework_load_error.tr()),
              TextButton(
                onPressed: () =>
                    ref.invalidate(studentSessionHomeworkProvider(key)),
                child: Text(LocaleKeys.common_retry.tr()),
              ),
            ],
            _ => [const LinearProgressIndicator()],
          },
        ],
      ),
    );
  }
}
