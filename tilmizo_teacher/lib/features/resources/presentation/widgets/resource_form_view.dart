import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../profile/presentation/controllers/resource_storage_usage_controller.dart';
import '../../data/resource_file_picker.dart';
import '../../domain/resource_models.dart';
import '../controllers/resource_form_controller.dart';
import '../resource_labels.dart';
import 'resource_detail_fields.dart';
import 'resource_file_field.dart';
import 'resource_session_field.dart';
import 'resource_type_header.dart';
import 'upload_progress_panel.dart';

/// Create form for [initialType], or metadata edit form for [resource].
class ResourceFormView extends ConsumerStatefulWidget {
  const ResourceFormView({
    super.key,
    required this.groupId,
    required this.initialType,
    this.resource,
    this.initialSessionId,
  });

  final String groupId;
  final ResourceType initialType;

  /// The resource being edited; uploaded content cannot be replaced.
  final GroupResource? resource;

  /// The session preselected for a new resource.
  final String? initialSessionId;

  @override
  ConsumerState<ResourceFormView> createState() => _ResourceFormViewState();
}

class _ResourceFormViewState extends ConsumerState<ResourceFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.resource?.title);
  late final _description = TextEditingController(
    text: widget.resource?.description,
  );
  late final _url = TextEditingController(text: widget.resource?.externalUrl);
  late ResourceType _type = widget.initialType;
  late String? _sessionId =
      widget.resource?.sessionId ?? widget.initialSessionId;
  PickedResourceFile? _file;
  String? _fileError;

  bool get _isEdit => widget.resource != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _url.dispose();
    super.dispose();
  }

  ResourceDetails get _details => ResourceDetails(
    title: _title.text.trim(),
    description: _description.text.trim().isEmpty
        ? null
        : _description.text.trim(),
    sessionId: _sessionId,
  );

  Future<void> _pickFile() async {
    final file = await ref.read(resourceFilePickerProvider).pick(_type);
    if (file == null || !mounted) return;
    setState(() {
      _file = file;
      _fileError = _validateFile(file);
    });
  }

  String? _validateFile(PickedResourceFile file) {
    final limits = ref.read(resourceStorageUsageProvider).value?.uploadLimits;
    if (limits == null) return null;
    final problem = validateResourceFile(
      type: _type,
      fileName: file.name,
      mimeType: file.mimeType,
      sizeBytes: file.size,
      limits: limits,
    );
    return resourceFileProblemMessage(problem, _type, limits);
  }

  void _changeType(ResourceType type) => setState(() {
    _type = type;
    _file = null;
    _fileError = null;
  });

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final needsFile = !_isEdit && _type.isUpload;
    if (needsFile && _file == null) {
      setState(() => _fileError = LocaleKeys.resource_form_file_required.tr());
    }
    if (!formValid || (needsFile && (_file == null || _fileError != null))) {
      return;
    }
    final controller = ref.read(
      resourceFormControllerProvider(widget.groupId).notifier,
    );
    final url = _url.text.trim();
    final saved = switch (widget.resource) {
      final resource? => await controller.updateMetadata(
        resource: resource,
        details: _details,
        url: resource.type.isLink ? url : null,
      ),
      null when _type.isLink => await controller.createLink(
        type: _type,
        url: url,
        details: _details,
      ),
      null => await controller.upload(
        type: _type,
        file: _file!,
        details: _details,
      ),
    };
    if (saved == null || !mounted) return;
    showTelmizoSnackBar(
      context,
      _isEdit
          ? LocaleKeys.resource_form_saved.tr()
          : LocaleKeys.resource_form_created.tr(),
    );
    await context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = resourceFormControllerProvider(widget.groupId);
    final state = ref.watch(provider);
    final limits = ref.watch(resourceStorageUsageProvider).value?.uploadLimits;
    final enabled = !state.isBusy;
    return PopScope(
      canPop: !state.isUploading,
      child: Form(
        key: _formKey,
        child: TelmizoScrollBody(
          children: [
            ResourceTypeHeader(
              type: _type,
              limits: limits,
              onChanged: _isEdit || !enabled ? null : _changeType,
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            TelmizoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_type.isLink)
                    ResourceUrlField(controller: _url, enabled: enabled)
                  else if (_isEdit)
                    TelmizoInlineMessage(
                      message: LocaleKeys.resource_form_file_immutable.tr(),
                      tone: TelmizoMessageTone.info,
                    )
                  else
                    ResourceFileField(
                      type: _type,
                      file: _file,
                      limits: limits,
                      errorText: _fileError,
                      enabled: enabled,
                      onPick: _pickFile,
                    ),
                  const SizedBox(height: TelmizoSpacing.lg),
                  ResourceDetailFields(
                    title: _title,
                    description: _description,
                    enabled: enabled,
                  ),
                  const SizedBox(height: TelmizoSpacing.lg),
                  ResourceSessionField(
                    groupId: widget.groupId,
                    sessionId: _sessionId,
                    enabled: enabled,
                    onChanged: (id) => setState(() => _sessionId = id),
                  ),
                ],
              ),
            ),
            if (state.isUploading) ...[
              const SizedBox(height: TelmizoSpacing.lg),
              UploadProgressPanel(
                state: state,
                onCancel: ref.read(provider.notifier).cancelUpload,
              ),
            ],
            if (state.wasCancelled) ...[
              const SizedBox(height: TelmizoSpacing.lg),
              TelmizoInlineMessage(
                message: LocaleKeys.resource_upload_cancelled.tr(),
                tone: TelmizoMessageTone.info,
              ),
            ],
            if (state.failure case final failure?) ...[
              const SizedBox(height: TelmizoSpacing.lg),
              TelmizoInlineMessage(message: resourceFailureMessage(failure)),
            ],
            const SizedBox(height: TelmizoSpacing.xl),
            TelmizoPrimaryButton(
              key: const Key('resource-submit'),
              label: switch ((_isEdit, state.failure != null)) {
                (true, _) => LocaleKeys.resource_form_save.tr(),
                (false, true) => LocaleKeys.resource_upload_retry.tr(),
                _ => LocaleKeys.resource_form_publish.tr(),
              },
              icon: _isEdit ? Icons.save_outlined : Icons.cloud_upload_outlined,
              isLoading: state.phase == ResourceSubmitPhase.saving,
              onPressed: enabled ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
