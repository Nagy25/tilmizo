import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/class_session.dart';
import '../formatting/session_formatting.dart';
import 'session_notes_field.dart';

Future<bool> confirmSessionCancel(
  BuildContext context,
  ClassSession session,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.warning_amber, color: TelmizoColors.error),
      title: Text(LocaleKeys.session_cancel_title.tr()),
      content: Text(
        LocaleKeys.session_cancel_body.tr(
          args: [
            session.group.name,
            '${context.cairoDate(session.startsAt)} • '
                '${context.cairoTime(session.startsAt)}',
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(LocaleKeys.common_back.tr()),
        ),
        FilledButton(
          key: const Key('confirm-cancel-session'),
          style: FilledButton.styleFrom(backgroundColor: TelmizoColors.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(LocaleKeys.session_cancel_confirm.tr()),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Edits the session note. Returns the new text, or null when dismissed.
Future<String?> showSessionNotesSheet(BuildContext context, String? current) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _NotesSheet(initial: current),
    );

class _NotesSheet extends StatefulWidget {
  const _NotesSheet({this.initial});

  final String? initial;

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          0,
          TelmizoSpacing.margin,
          TelmizoSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocaleKeys.session_notes_edit.tr(),
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: TelmizoSpacing.md),
              SessionNotesField(controller: _controller),
              const SizedBox(height: TelmizoSpacing.md),
              TelmizoPrimaryButton(
                key: const Key('save-session-notes'),
                label: LocaleKeys.common_save.tr(),
                icon: Icons.save_outlined,
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  Navigator.of(context).pop(_controller.text);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
