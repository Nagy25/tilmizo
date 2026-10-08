import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../controllers/student_homework_providers.dart';
import '../homework_labels.dart';
import '../widgets/homework_attachments_card.dart';
import '../widgets/homework_link_section.dart';
import '../widgets/student_homework_tab.dart';

/// One homework: instructions, due date, method, files, and the student's
/// link for link-type homework. Opened from the group list and the session.
@RoutePage()
class StudentHomeworkDetailsScreen extends ConsumerStatefulWidget {
  const StudentHomeworkDetailsScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
    @PathParam('homeworkId') required this.homeworkId,
  });

  final String groupId;
  final String homeworkId;

  @override
  ConsumerState<StudentHomeworkDetailsScreen> createState() =>
      _StudentHomeworkDetailsScreenState();
}

class _StudentHomeworkDetailsScreenState
    extends ConsumerState<StudentHomeworkDetailsScreen> {
  late final AppLifecycleListener _lifecycle;

  GroupHomeworkKey get _key => (groupId: widget.groupId, id: widget.homeworkId);

  @override
  void initState() {
    super.initState();
    // Homework tables are not in Supabase Realtime; reload on resume.
    _lifecycle = AppLifecycleListener(onResume: _reload);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _reload() => refreshStudentHomework(ref, widget.groupId);

  Future<void> _refresh() async {
    try {
      await ref.read(groupAccessOverviewProvider.notifier).refresh();
    } on AppFailure {
      // The gated providers show the failure.
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final homework = ref.watch(studentHomeworkProvider(_key));
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.homework_details_title.tr())),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(TelmizoSpacing.margin),
          children: switch (homework) {
            AsyncData(:final value) => _content(value),
            AsyncError(:final error) => [
              HomeworkStateMessage.error(
                key: const Key('student-homework-details-error'),
                error: error,
                onRetry: _reload,
              ),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(TelmizoSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ),
      ),
    );
  }

  List<Widget> _content(Homework homework) {
    final textTheme = context.textTheme;
    final type = homework.submissionType;
    return [
      TelmizoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.homeworkHeading(homework),
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: TelmizoSpacing.md),
            _Fact(icon: type.icon, text: type.label),
            const SizedBox(height: TelmizoSpacing.sm),
            _Fact(
              icon: Icons.event_outlined,
              text: context.homeworkDue(homework),
            ),
            if (homework.session?.isCancelled ?? false) ...[
              const SizedBox(height: TelmizoSpacing.md),
              TelmizoInlineMessage(
                message: LocaleKeys.homework_session_cancelled.tr(),
                tone: TelmizoMessageTone.warning,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: TelmizoSpacing.md),
      TelmizoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.homework_instructions_title.tr(),
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            SelectableText(
              homework.instructions ?? LocaleKeys.homework_no_instructions.tr(),
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      if (homework.attachments.isNotEmpty) ...[
        const SizedBox(height: TelmizoSpacing.md),
        HomeworkAttachmentsCard(homeworkKey: _key, homework: homework),
      ],
      const SizedBox(height: TelmizoSpacing.md),
      switch (type) {
        HomeworkSubmissionType.link => HomeworkLinkSection(
          homeworkKey: _key,
          homework: homework,
        ),
        HomeworkSubmissionType.manual => TelmizoInlineMessage(
          key: const Key('homework-manual-note'),
          title: LocaleKeys.homework_manual_title.tr(),
          message: LocaleKeys.homework_manual_body.tr(),
          tone: TelmizoMessageTone.info,
        ),
        HomeworkSubmissionType.none => TelmizoInlineMessage(
          key: const Key('homework-none-note'),
          message: LocaleKeys.homework_none_body.tr(),
          tone: TelmizoMessageTone.info,
        ),
      },
    ];
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: TelmizoColors.primary),
      const SizedBox(width: TelmizoSpacing.sm),
      Expanded(child: Text(text)),
    ],
  );
}
