import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/formatting/byte_size.dart';
import '../../../../generated/locale_keys.g.dart';
import '../resource_labels.dart';

/// The add-resource type picker. Each choice maps to one exact backend type;
/// upload limits come from `get_my_resource_storage_usage()` when loaded.
Future<ResourceType?> showResourceTypeSheet(
  BuildContext context, {
  ResourceUploadLimits? limits,
}) => showModalBottomSheet<ResourceType>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _ResourceTypeSheet(limits: limits),
);

class _ResourceTypeSheet extends StatelessWidget {
  const _ResourceTypeSheet({required this.limits});

  final ResourceUploadLimits? limits;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          0,
          TelmizoSpacing.margin,
          TelmizoSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.resource_type_sheet_title.tr(),
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: TelmizoSpacing.xs),
            Text(
              LocaleKeys.resource_type_sheet_subtitle.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.md),
            for (final type in ResourceType.values)
              ListTile(
                key: Key('resource-type-${type.backendValue}'),
                contentPadding: EdgeInsets.zero,
                leading: ResourceTypeIcon(type: type, size: 44),
                title: Text(type.label),
                subtitle: Text(type.pickerBody),
                trailing: _LimitLabel(type: type, limits: limits),
                onTap: () => Navigator.of(context).pop(type),
              ),
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              message: LocaleKeys.resource_type_sheet_note.tr(),
              tone: TelmizoMessageTone.info,
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitLabel extends StatelessWidget {
  const _LimitLabel({required this.type, required this.limits});

  final ResourceType type;
  final ResourceUploadLimits? limits;

  @override
  Widget build(BuildContext context) {
    final maxBytes = limits?.maxBytesFor(type);
    final text = type.isLink
        ? LocaleKeys.resource_type_https_only.tr()
        : maxBytes == null
        ? null
        : LocaleKeys.resource_type_limit.tr(args: [formatByteSize(maxBytes)]);
    if (text == null) return const SizedBox.shrink();
    return Text(
      text,
      style: context.textTheme.labelSmall?.copyWith(
        color: TelmizoColors.onSurfaceVariant,
      ),
    );
  }
}
