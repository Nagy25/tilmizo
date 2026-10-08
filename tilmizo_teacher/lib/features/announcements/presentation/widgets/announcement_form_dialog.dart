import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/announcements_repository.dart';
import '../announcement_labels.dart';
import '../controllers/announcements_providers.dart';

/// Opens the publish dialog. Resolves to true after the RPC succeeded and
/// the feed was refreshed. Published announcements cannot be edited.
Future<bool> showAnnouncementFormDialog(
  BuildContext context, {
  required String groupId,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AnnouncementFormDialog(groupId: groupId),
  );
  return saved ?? false;
}

class AnnouncementFormDialog extends ConsumerStatefulWidget {
  const AnnouncementFormDialog({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState
    extends ConsumerState<AnnouncementFormDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final draft = AnnouncementDraft(title: _title.text, body: _body.text);
    final feed = ref.read(announcementsFeedProvider(widget.groupId).notifier);
    try {
      await feed.create(draft);
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = announcementFailureMessage(failure);
      });
    }
  }

  String? _validate(String? value, int maxLength, String required) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required;
    if (!isValidAnnouncementText(text, maxLength)) {
      return (maxLength == Announcement.titleMaxLength
              ? LocaleKeys.announcement_form_title_too_long
              : LocaleKeys.announcement_form_body_too_long)
          .tr(args: ['$maxLength']);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Dialog(
      key: const Key('announcement-form-dialog'),
      insetPadding: const EdgeInsets.all(TelmizoSpacing.md),
      shape: const RoundedRectangleBorder(borderRadius: TelmizoRadius.xlAll),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: TelmizoSpacing.maxContentWidth + TelmizoSpacing.xl,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TelmizoSpacing.lg),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: TelmizoColors.primaryTint,
                      foregroundColor: TelmizoColors.primary,
                      child: Icon(Icons.campaign_outlined),
                    ),
                    const SizedBox(width: TelmizoSpacing.md),
                    Expanded(
                      child: Text(
                        LocaleKeys.announcement_form_add_title.tr(),
                        style: textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.common_cancel.tr(),
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: TelmizoSpacing.md),
                TelmizoInlineMessage(
                  message: LocaleKeys.announcement_form_add_subtitle.tr(),
                  tone: TelmizoMessageTone.info,
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                TelmizoFormField(
                  label: LocaleKeys.announcement_form_title_label.tr(),
                  isRequired: true,
                  child: TextFormField(
                    key: const Key('announcement-title'),
                    controller: _title,
                    enabled: !_saving,
                    maxLength: Announcement.titleMaxLength,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: LocaleKeys.announcement_form_title_hint.tr(),
                      counterText: '',
                    ),
                    validator: (value) => _validate(
                      value,
                      Announcement.titleMaxLength,
                      LocaleKeys.announcement_form_title_required.tr(),
                    ),
                  ),
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                TelmizoFormField(
                  label: LocaleKeys.announcement_form_body_label.tr(),
                  isRequired: true,
                  child: TextFormField(
                    key: const Key('announcement-body'),
                    controller: _body,
                    enabled: !_saving,
                    minLines: 5,
                    maxLines: 10,
                    maxLength: Announcement.bodyMaxLength,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: LocaleKeys.announcement_form_body_hint.tr(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => _validate(
                      value,
                      Announcement.bodyMaxLength,
                      LocaleKeys.announcement_form_body_required.tr(),
                    ),
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: TelmizoSpacing.md),
                  TelmizoInlineMessage(
                    key: const Key('announcement-form-error'),
                    message: error,
                  ),
                ],
                const SizedBox(height: TelmizoSpacing.lg),
                TelmizoPrimaryButton(
                  key: const Key('announcement-submit'),
                  label: LocaleKeys.announcement_form_publish.tr(),
                  icon: Icons.send_outlined,
                  isLoading: _saving,
                  onPressed: _submit,
                ),
                const SizedBox(height: TelmizoSpacing.sm),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(LocaleKeys.common_cancel.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
