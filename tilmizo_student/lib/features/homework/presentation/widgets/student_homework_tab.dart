import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../group_access/presentation/widgets/approved_group_tab_list.dart';
import '../controllers/student_homework_providers.dart';
import 'student_homework_card.dart';

/// The approved group's homework, newest first.
class StudentHomeworkTab extends ConsumerWidget {
  const StudentHomeworkTab({
    super.key,
    required this.groupId,
    required this.onRefresh,
  });

  final String groupId;

  /// Refreshes access and every tab of the group screen.
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(studentGroupHomeworkProvider(groupId));
    return ApprovedGroupTabList(
      onRefresh: onRefresh,
      children: [
        TelmizoInlineMessage(
          message: LocaleKeys.homework_intro.tr(),
          tone: TelmizoMessageTone.info,
        ),
        const SizedBox(height: TelmizoSpacing.md),
        ...switch (homework) {
          AsyncData(:final value) when value.isEmpty => [
            HomeworkStateMessage(
              key: const Key('student-homework-empty'),
              icon: Icons.assignment_outlined,
              title: LocaleKeys.homework_empty_title.tr(),
              body: LocaleKeys.homework_empty_body.tr(),
            ),
          ],
          AsyncData(:final value) => [
            for (final item in value) ...[
              StudentHomeworkCard(
                homework: item,
                onTap: () => context.router.push(
                  StudentHomeworkDetailsRoute(
                    groupId: groupId,
                    homeworkId: item.id,
                  ),
                ),
              ),
              const SizedBox(height: TelmizoSpacing.md),
            ],
          ],
          AsyncError(:final error) => [
            HomeworkStateMessage.error(
              key: const Key('student-homework-error'),
              error: error,
              onRetry: () => refreshStudentHomework(ref, groupId),
            ),
          ],
          _ => [
            const Padding(
              padding: EdgeInsets.all(TelmizoSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        },
      ],
    );
  }
}

/// Empty, access-lost and load-error cards for homework views.
class HomeworkStateMessage extends StatelessWidget {
  const HomeworkStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  /// A load failure; not-found means this session lost access.
  factory HomeworkStateMessage.error({
    Key? key,
    required Object error,
    required VoidCallback onRetry,
  }) {
    final type = failureTypeOf(error);
    final accessLost = type == AppFailureType.notFound;
    return HomeworkStateMessage(
      key: key,
      icon: accessLost ? Icons.lock_outline : Icons.cloud_off_outlined,
      title: accessLost
          ? LocaleKeys.homework_access_lost_title.tr()
          : LocaleKeys.homework_load_error_title.tr(),
      body: accessLost
          ? LocaleKeys.homework_access_lost_body.tr()
          : appFailureMessage(type),
      onRetry: onRetry,
    );
  }

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Column(
      children: [
        Icon(icon, size: 40, color: TelmizoColors.onSurfaceVariant),
        const SizedBox(height: TelmizoSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: TelmizoSpacing.xs),
        Text(body, textAlign: TextAlign.center),
        if (onRetry case final onRetry?)
          TextButton(
            onPressed: onRetry,
            child: Text(LocaleKeys.common_retry.tr()),
          ),
      ],
    ),
  );
}
