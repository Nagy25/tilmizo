import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/formatting/byte_size.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/resource_models.dart';

/// Picks the file for a new upload and explains the backend limits.
class ResourceFileField extends StatelessWidget {
  const ResourceFileField({
    super.key,
    required this.type,
    required this.file,
    required this.limits,
    required this.errorText,
    required this.enabled,
    required this.onPick,
  });

  final ResourceType type;
  final PickedResourceFile? file;
  final ResourceUploadLimits? limits;
  final String? errorText;
  final bool enabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final picked = file;
    return TelmizoFormField(
      label: LocaleKeys.resource_form_file_label.tr(),
      isRequired: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (picked != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ResourceTypeIcon(type: type, size: 40),
              title: Text(
                picked.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                LocaleKeys.resource_form_file_size.tr(
                  args: [formatByteSize(picked.size)],
                ),
              ),
            ),
          OutlinedButton.icon(
            key: const Key('resource-pick-file'),
            onPressed: enabled ? onPick : null,
            icon: const Icon(Icons.upload_file),
            label: Text(
              picked == null
                  ? LocaleKeys.resource_form_pick_file.tr()
                  : LocaleKeys.resource_form_pick_another.tr(),
            ),
          ),
          if (_rules() case final rules?) ...[
            const SizedBox(height: TelmizoSpacing.xs),
            Text(
              rules,
              style: textTheme.bodySmall?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
          ],
          if (errorText != null) ...[
            const SizedBox(height: TelmizoSpacing.xs),
            Text(
              errorText!,
              style: textTheme.bodySmall?.copyWith(color: TelmizoColors.error),
            ),
          ],
        ],
      ),
    );
  }

  String? _rules() {
    final maxBytes = limits?.maxBytesFor(type);
    if (maxBytes == null) return null;
    final key = switch (type) {
      ResourceType.pdf => LocaleKeys.resource_form_rules_pdf,
      ResourceType.image => LocaleKeys.resource_form_rules_image,
      ResourceType.uploadedVideo => LocaleKeys.resource_form_rules_video,
      _ => LocaleKeys.resource_form_rules_file,
    };
    return key.tr(args: [formatByteSize(maxBytes)]);
  }
}

/// Local feedback for a picked file; the backend check is authoritative.
String? resourceFileProblemMessage(
  ResourceFileProblem? problem,
  ResourceType type,
  ResourceUploadLimits limits,
) => switch (problem) {
  null => null,
  ResourceFileProblem.empty => LocaleKeys.resource_form_file_empty.tr(),
  ResourceFileProblem.nameTooLong =>
    LocaleKeys.resource_form_file_name_too_long.tr(),
  ResourceFileProblem.wrongFormat =>
    LocaleKeys.resource_form_file_wrong_format.tr(),
  ResourceFileProblem.tooLarge => LocaleKeys.resource_form_file_too_large.tr(
    args: [formatByteSize(limits.maxBytesFor(type) ?? 0)],
  ),
  ResourceFileProblem.quotaExceeded => LocaleKeys.resource_form_file_quota.tr(
    args: [formatByteSize(limits.remainingBytes)],
  ),
};
