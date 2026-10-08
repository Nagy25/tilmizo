import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../controllers/homework_providers.dart';
import '../homework_labels.dart';
import '../widgets/delete_homework_dialog.dart';
import '../widgets/homework_attachments_section.dart';
import '../widgets/homework_submissions_section.dart';

/// Full homework details with attachments, students' links for link-type
/// homework, and Delete. There is no Edit: correct by delete and recreate.
@RoutePage()
class HomeworkDetailsScreen extends ConsumerWidget {
  const HomeworkDetailsScreen({
    super.key,
    @PathParam('homeworkId') required this.homeworkId,
  });

  final String homeworkId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Homework homework,
  ) async {
    if (!await confirmHomeworkDelete(context) || !context.mounted) return;
    final actions = ref.read(homeworkActionsProvider.notifier);
    if (await actions.delete(homework)) {
      if (!context.mounted) return;
      showTelmizoSnackBar(context, LocaleKeys.homework_deleted.tr());
      await context.router.maybePop();
    } else if (context.mounted) {
      final failure = ref.read(homeworkActionsProvider).failure;
      showTelmizoSnackBar(context, homeworkFailureMessage(failure));
    }
  }

  Future<void> _refresh(WidgetRef ref) {
    ref
      ..invalidate(homeworkAttachmentsProvider(homeworkId))
      ..invalidate(homeworkSubmissionsProvider(homeworkId));
    // A failed reload shows on the page; the indicator just stops.
    return ref
        .refresh(homeworkDetailsProvider(homeworkId).future)
        .then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homework = ref.watch(homeworkDetailsProvider(homeworkId));
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.homework_details_title.tr(),
        showBack: true,
      ),
      body: homework.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) => TelmizoErrorView(
          icon: Icons.search_off,
          title: LocaleKeys.homework_not_found_title.tr(),
          message: homeworkFailureMessage(error),
          retryLabel: LocaleKeys.common_retry.tr(),
          onRetry: () => ref.invalidate(homeworkDetailsProvider(homeworkId)),
        ),
        data: (homework) {
          final group = ref.watch(groupDetailsProvider(homework.groupId));
          final canDelete =
              (group.value?.acceptsNewEntries ?? false) &&
              !(homework.session?.isCancelled ?? false);
          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(TelmizoSpacing.margin),
              children: [
                _Summary(homework: homework),
                const SizedBox(height: TelmizoSpacing.md),
                _Instructions(homework: homework),
                const SizedBox(height: TelmizoSpacing.md),
                HomeworkAttachmentsSection(homework: homework),
                if (homework.submissionType == HomeworkSubmissionType.link) ...[
                  const SizedBox(height: TelmizoSpacing.md),
                  HomeworkSubmissionsSection(homeworkId: homework.id),
                ],
                if (canDelete) ...[
                  const SizedBox(height: TelmizoSpacing.lg),
                  OutlinedButton.icon(
                    key: const Key('delete-homework'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TelmizoColors.error,
                    ),
                    onPressed: ref.watch(homeworkActionsProvider).isBusy
                        ? null
                        : () => _delete(context, ref, homework),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(LocaleKeys.homework_delete.tr()),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.homework});

  final Homework homework;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final type = homework.submissionType;
    return TelmizoCard(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.homeworkHeading(homework),
              style: textTheme.titleLarge,
            ),
            Text(
              LocaleKeys.homework_created_on.tr(
                args: [context.homeworkInstant(homework.createdAt)],
              ),
              style: textTheme.labelMedium?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(type.icon, color: TelmizoColors.primary),
              title: Text(type.label),
              subtitle: Text(type.body),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.event_outlined,
                color: TelmizoColors.primary,
              ),
              title: Text(context.homeworkDue(homework)),
            ),
            if (homework.session?.isCancelled ?? false)
              TelmizoInlineMessage(
                message: LocaleKeys.homework_session_cancelled.tr(),
                tone: TelmizoMessageTone.warning,
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.router.push(
                  SessionDetailsRoute(sessionId: homework.sessionId),
                ),
                icon: const Icon(Icons.event_note_outlined),
                label: Text(LocaleKeys.homework_open_session.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({required this.homework});

  final Homework homework;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.homework_instructions_title.tr(),
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        SelectableText(
          homework.instructions ?? LocaleKeys.homework_no_instructions.tr(),
          style: context.textTheme.bodyLarge,
        ),
      ],
    ),
  );
}
