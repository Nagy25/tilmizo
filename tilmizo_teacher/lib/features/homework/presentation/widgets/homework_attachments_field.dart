import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../resources/presentation/resource_labels.dart';
import '../controllers/homework_providers.dart';

/// Picks uploaded Resources that `create_homework` accepts for the session,
/// with an entry to the existing upload flow.
class HomeworkAttachmentsField extends ConsumerWidget {
  const HomeworkAttachmentsField({
    super.key,
    required this.query,
    required this.selected,
    required this.onToggle,
    required this.onUpload,
    required this.enabled,
  });

  final AttachableQuery query;
  final Set<String> selected;
  final void Function(String resourceId, bool selected) onToggle;
  final VoidCallback onUpload;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = ref.watch(attachableResourcesProvider(query));
    return TelmizoFormField(
      label: LocaleKeys.homework_form_files_label.tr(),
      qualifier: LocaleKeys.common_optional.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.homework_form_files_note.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          ...switch (resources) {
            AsyncData(:final value) when value.isEmpty => [
              Text(LocaleKeys.homework_form_files_empty.tr()),
            ],
            AsyncData(:final value) => [
              for (final resource in value)
                CheckboxListTile(
                  key: Key('attach-${resource.id}'),
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(resource.id),
                  onChanged: enabled
                      ? (value) => onToggle(resource.id, value ?? false)
                      : null,
                  secondary: ResourceThumbnail(resource: resource, size: 40),
                  title: Text(resource.title),
                  subtitle: Text(resource.type.label),
                ),
            ],
            AsyncError() => [
              Text(LocaleKeys.homework_form_files_load_error.tr()),
              TextButton(
                onPressed: () =>
                    ref.invalidate(attachableResourcesProvider(query)),
                child: Text(LocaleKeys.common_retry.tr()),
              ),
            ],
            _ => [const LinearProgressIndicator()],
          },
          const SizedBox(height: TelmizoSpacing.sm),
          TelmizoSecondaryButton(
            key: const Key('homework-upload-file'),
            label: LocaleKeys.homework_form_upload.tr(),
            icon: Icons.upload_file_outlined,
            onPressed: enabled ? onUpload : null,
          ),
        ],
      ),
    );
  }
}
