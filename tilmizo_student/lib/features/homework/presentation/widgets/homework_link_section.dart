import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../controllers/student_homework_providers.dart';
import '../homework_labels.dart';

/// The student's link for link-type homework: save or replace it until the
/// end of the Cairo due date, then read-only.
class HomeworkLinkSection extends ConsumerStatefulWidget {
  const HomeworkLinkSection({
    super.key,
    required this.homeworkKey,
    required this.homework,
  });

  final GroupHomeworkKey homeworkKey;
  final Homework homework;

  @override
  ConsumerState<HomeworkLinkSection> createState() =>
      _HomeworkLinkSectionState();
}

class _HomeworkLinkSectionState extends ConsumerState<HomeworkLinkSection> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  var _editing = false;
  var _serverClosed = false;
  String? _fieldError;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _startEditing(HomeworkLinkSubmission? saved) => setState(() {
    _editing = true;
    _fieldError = null;
    _url.text = saved?.url ?? '';
  });

  Future<void> _save() async {
    setState(() => _fieldError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final outcome = await ref
        .read(linkSubmitControllerProvider(widget.homeworkKey).notifier)
        .submit(_url.text);
    if (!mounted) return;
    switch (outcome) {
      case LinkSubmitOutcome.saved:
        setState(() => _editing = false);
        showTelmizoSnackBar(context, LocaleKeys.homework_link_saved.tr());
      case LinkSubmitOutcome.invalidLink:
        setState(() => _fieldError = LocaleKeys.homework_link_invalid.tr());
      case LinkSubmitOutcome.closed:
        setState(() => _serverClosed = true);
      case LinkSubmitOutcome.accessLost:
        // The gated providers now report lost access on this screen.
        break;
      case LinkSubmitOutcome.failed:
        final failure = ref
            .read(linkSubmitControllerProvider(widget.homeworkKey))
            .failure;
        showTelmizoSnackBar(
          context,
          appFailureMessage(failure ?? AppFailureType.unknown),
        );
    }
  }

  Future<void> _openLink(String url) async {
    try {
      if (await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // Reported below.
    }
    if (mounted) {
      showTelmizoSnackBar(context, LocaleKeys.homework_link_open_failed.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final homework = widget.homework;
    final submission = ref.watch(
      myHomeworkSubmissionProvider(widget.homeworkKey),
    );
    final saving = ref
        .watch(linkSubmitControllerProvider(widget.homeworkKey))
        .isSaving;
    final now = ref.watch(clockProvider)();
    final open = homework.acceptsSubmissionAt(now) && !_serverClosed;
    final textTheme = context.textTheme;
    return TelmizoCard(
      key: const Key('homework-link-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.homework_link_title.tr(),
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          if (open)
            Text(
              homework.dueDate == null
                  ? LocaleKeys.homework_link_intro_no_due.tr()
                  : LocaleKeys.homework_link_intro.tr(),
              style: textTheme.bodySmall,
            )
          else
            TelmizoInlineMessage(
              key: const Key('homework-link-closed'),
              message: switch (homework.dueDate) {
                final due? when !homework.acceptsSubmissionAt(now) =>
                  LocaleKeys.homework_link_closed.tr(
                    args: [context.calendarDate(due)],
                  ),
                _ => LocaleKeys.homework_link_closed_server.tr(),
              },
              tone: TelmizoMessageTone.warning,
            ),
          const SizedBox(height: TelmizoSpacing.md),
          ...switch (submission) {
            AsyncData(:final value) => _content(value, open, saving),
            AsyncError() => [
              Text(LocaleKeys.homework_link_load_error.tr()),
              TextButton(
                onPressed: () => ref.invalidate(
                  myHomeworkSubmissionProvider(widget.homeworkKey),
                ),
                child: Text(LocaleKeys.common_retry.tr()),
              ),
            ],
            _ => [const LinearProgressIndicator()],
          },
        ],
      ),
    );
  }

  List<Widget> _content(HomeworkLinkSubmission? saved, bool open, bool saving) {
    final editing = open && (_editing || saved == null);
    return [
      Text(
        LocaleKeys.homework_link_saved_label.tr(),
        style: context.textTheme.labelLarge,
      ),
      const SizedBox(height: TelmizoSpacing.xs),
      if (saved == null)
        Text(LocaleKeys.homework_link_none_saved.tr())
      else ...[
        SelectableText(
          saved.url,
          key: const Key('homework-saved-link'),
          textDirection: TextDirection.ltr,
        ),
        Text(
          LocaleKeys.homework_link_updated_at.tr(
            args: [context.homeworkInstant(saved.updatedAt)],
          ),
          style: context.textTheme.labelSmall,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _openLink(saved.url),
            icon: const Icon(Icons.open_in_new),
            label: Text(LocaleKeys.homework_link_open.tr()),
          ),
        ),
      ],
      if (editing) ...[
        const SizedBox(height: TelmizoSpacing.md),
        Form(
          key: _formKey,
          child: TextFormField(
            key: const Key('homework-link-field'),
            controller: _url,
            enabled: !saving,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: LocaleKeys.homework_link_label.tr(),
              hintText: 'https://',
              prefixIcon: const Icon(Icons.link),
              errorText: _fieldError,
              errorMaxLines: 2,
            ),
            validator: (value) => isValidHomeworkLink(value?.trim() ?? '')
                ? null
                : LocaleKeys.homework_link_invalid.tr(),
          ),
        ),
        const SizedBox(height: TelmizoSpacing.md),
        TelmizoPrimaryButton(
          key: const Key('homework-link-save'),
          label: LocaleKeys.homework_link_save.tr(),
          icon: Icons.check,
          isLoading: saving,
          onPressed: _save,
        ),
      ] else if (open && saved != null) ...[
        const SizedBox(height: TelmizoSpacing.md),
        TelmizoSecondaryButton(
          key: const Key('homework-link-edit'),
          label: LocaleKeys.homework_link_edit.tr(),
          icon: Icons.edit_outlined,
          onPressed: () => _startEditing(saved),
        ),
      ],
    ];
  }
}
