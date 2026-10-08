import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../classes/domain/class_session.dart';
import '../../../profile/presentation/controllers/resource_storage_usage_controller.dart';
import '../../../resources/presentation/widgets/resource_type_sheet.dart';
import '../../domain/homework_repository.dart';
import '../controllers/homework_providers.dart';
import '../homework_labels.dart';
import 'homework_attachments_field.dart';
import 'homework_options_fields.dart';

/// Instructions, attachments, submission method and optional due date for
/// new homework of [session].
class HomeworkFormView extends ConsumerStatefulWidget {
  const HomeworkFormView({super.key, required this.session});

  final ClassSession session;

  @override
  ConsumerState<HomeworkFormView> createState() => _HomeworkFormViewState();
}

class _HomeworkFormViewState extends ConsumerState<HomeworkFormView> {
  final _formKey = GlobalKey<FormState>();
  final _instructions = TextEditingController();
  final _selected = <String>{};
  var _type = HomeworkSubmissionType.manual;
  DateTime? _dueDate;
  String? _error;

  AttachableQuery get _query =>
      (groupId: widget.session.group.id, sessionId: widget.session.id);

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  /// Uploads through the existing Resource flow, then reloads the picker so
  /// the new file can be attached.
  Future<void> _upload() async {
    final limits = ref.read(resourceStorageUsageProvider).value?.uploadLimits;
    final type = await showResourceTypeSheet(
      context,
      limits: limits,
      types: ResourceType.values.where((type) => type.isUpload),
    );
    if (type == null || !mounted) return;
    await context.router.push(
      AddResourceRoute(
        groupId: _query.groupId,
        type: type.backendValue,
        sessionId: _query.sessionId,
      ),
    );
    ref.invalidate(attachableResourcesProvider(_query));
  }

  Future<void> _submit() async {
    final available = ref.read(attachableResourcesProvider(_query)).value;
    final draft = HomeworkDraft(
      sessionId: widget.session.id,
      instructions: _instructions.text,
      submissionType: _type,
      dueDate: _dueDate,
      resourceIds: [
        // Only files still offered by the picker.
        for (final resource in available ?? const <GroupResource>[])
          if (_selected.contains(resource.id)) resource.id,
      ],
    );
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(
      () => _error = draft.hasContent
          ? null
          : LocaleKeys.homework_form_content_required.tr(),
    );
    if (!formValid || !draft.hasContent) return;
    final created = await ref
        .read(homeworkActionsProvider.notifier)
        .create(groupId: widget.session.group.id, draft: draft);
    if (!mounted) return;
    if (created == null) {
      final failure = ref.read(homeworkActionsProvider).failure;
      setState(() => _error = homeworkFailureMessage(failure));
      return;
    }
    showTelmizoSnackBar(context, LocaleKeys.homework_created.tr());
    await context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(homeworkActionsProvider).isBusy;
    final today = CairoTime.dateOf(ref.watch(clockProvider)());
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(TelmizoSpacing.margin),
        children: [
          TelmizoInlineMessage(
            message: LocaleKeys.homework_form_intro.tr(),
            tone: TelmizoMessageTone.info,
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoFormField(
            label: LocaleKeys.homework_form_instructions_label.tr(),
            qualifier: LocaleKeys.common_optional.tr(),
            child: TextFormField(
              key: const Key('homework-instructions'),
              controller: _instructions,
              enabled: !busy,
              minLines: 4,
              maxLines: 10,
              maxLength: Homework.instructionsMaxLength,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: LocaleKeys.homework_form_instructions_hint.tr(),
              ),
              validator: (value) =>
                  (value?.trim().runes.length ?? 0) >
                      Homework.instructionsMaxLength
                  ? LocaleKeys.homework_form_instructions_too_long.tr(
                      args: ['${Homework.instructionsMaxLength}'],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          HomeworkAttachmentsField(
            query: _query,
            selected: _selected,
            enabled: !busy,
            onUpload: _upload,
            onToggle: (id, selected) => setState(
              () => selected ? _selected.add(id) : _selected.remove(id),
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          HomeworkTypeField(
            value: _type,
            enabled: !busy,
            onChanged: (type) => setState(() => _type = type),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          HomeworkDueDateField(
            value: _dueDate,
            today: today,
            enabled: !busy,
            onChanged: (date) => setState(() => _dueDate = date),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              key: const Key('homework-form-error'),
              message: error,
            ),
          ],
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoPrimaryButton(
            key: const Key('publish-homework'),
            label: LocaleKeys.homework_form_publish.tr(),
            icon: Icons.send_outlined,
            isLoading: busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
