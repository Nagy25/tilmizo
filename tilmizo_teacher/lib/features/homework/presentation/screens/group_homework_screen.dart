import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../controllers/homework_providers.dart';
import '../homework_labels.dart';
import '../widgets/homework_card.dart';
import '../widgets/homework_message.dart';

/// A group's homework, newest first. Homework is added from a session, so
/// this list has no add action of its own.
@RoutePage()
class GroupHomeworkScreen extends ConsumerWidget {
  const GroupHomeworkScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupDetailsProvider(groupId));
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.homework_title.tr(),
        subtitle: group.value?.name,
        showBack: true,
      ),
      body: group.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) {
          final type = failureTypeOf(error);
          return TelmizoErrorView(
            icon: type == AppFailureType.notFound
                ? Icons.search_off
                : Icons.cloud_off_outlined,
            title: type == AppFailureType.notFound
                ? LocaleKeys.group_not_found_title.tr()
                : LocaleKeys.groups_load_error_title.tr(),
            message: appFailureMessage(type),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(groupDetailsProvider(groupId)),
          );
        },
        data: (group) => _HomeworkList(group: group),
      ),
    );
  }
}

class _HomeworkList extends ConsumerWidget {
  const _HomeworkList({required this.group});

  final TeacherGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(groupHomeworkProvider(group.id));
    final canAdd = group.acceptsNewEntries;
    return RefreshIndicator(
      onRefresh: () async {
        // A failed reload shows in the list; the indicator just stops.
        await ref
            .refresh(groupHomeworkProvider(group.id).future)
            .then((_) {}, onError: (_) {});
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          TelmizoSpacing.md,
          TelmizoSpacing.margin,
          TelmizoSpacing.xl,
        ),
        children: [
          TelmizoInlineMessage(
            key: canAdd ? null : const Key('homework-read-only'),
            message: canAdd
                ? LocaleKeys.homework_from_session_hint.tr()
                : group.isActive
                ? LocaleKeys.homework_suspended_notice.tr()
                : LocaleKeys.homework_archived_notice.tr(),
            tone: TelmizoMessageTone.info,
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          ...switch (homework) {
            AsyncData(:final value) when value.isEmpty => [
              HomeworkMessage(
                key: const Key('homework-empty'),
                icon: Icons.assignment_outlined,
                title: LocaleKeys.homework_empty_title.tr(),
                body: canAdd
                    ? LocaleKeys.homework_empty_body.tr()
                    : LocaleKeys.homework_empty_read_only_body.tr(),
                actionLabel: canAdd
                    ? LocaleKeys.homework_open_classes.tr()
                    : null,
                onAction: () =>
                    context.router.push(ClassesRoute(groupId: group.id)),
              ),
            ],
            AsyncData(:final value) => [
              for (final item in value) ...[
                HomeworkCard(
                  homework: item,
                  onTap: () => context.router.push(
                    HomeworkDetailsRoute(homeworkId: item.id),
                  ),
                ),
                const SizedBox(height: TelmizoSpacing.md),
              ],
            ],
            AsyncError(:final error) => [
              HomeworkMessage(
                key: const Key('homework-error'),
                icon: Icons.cloud_off_outlined,
                title: LocaleKeys.homework_load_error_title.tr(),
                body: homeworkFailureMessage(error),
                actionLabel: LocaleKeys.common_retry.tr(),
                onAction: () => ref.invalidate(groupHomeworkProvider(group.id)),
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
      ),
    );
  }
}
