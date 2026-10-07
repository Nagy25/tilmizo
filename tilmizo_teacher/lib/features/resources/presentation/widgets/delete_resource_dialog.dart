import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/formatting/byte_size.dart';
import '../../../../generated/locale_keys.g.dart';
import '../resource_labels.dart';

/// Confirms permanent deletion of [resource].
Future<bool> confirmResourceDelete(
  BuildContext context,
  GroupResource resource, {
  String? sessionLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: TelmizoColors.error),
      title: Text(LocaleKeys.resource_delete_title.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(LocaleKeys.resource_delete_body.tr(args: [resource.title])),
            const SizedBox(height: TelmizoSpacing.md),
            _Fact(
              label: LocaleKeys.resource_delete_type.tr(),
              value: resource.type.label,
            ),
            if (resource.fileSize case final size?)
              _Fact(
                label: LocaleKeys.resource_delete_size.tr(),
                value: formatByteSize(size),
              ),
            if (sessionLabel != null)
              _Fact(
                label: LocaleKeys.resource_delete_session.tr(),
                value: sessionLabel,
              ),
            const SizedBox(height: TelmizoSpacing.sm),
            Text(
              LocaleKeys.resource_delete_irreversible.tr(),
              style: dialogContext.textTheme.bodySmall?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(LocaleKeys.common_cancel.tr()),
        ),
        FilledButton(
          key: const Key('confirm-resource-delete'),
          style: FilledButton.styleFrom(backgroundColor: TelmizoColors.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(LocaleKeys.resource_delete_confirm.tr()),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TelmizoSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ),
        Flexible(child: Text(value, style: context.textTheme.labelLarge)),
      ],
    ),
  );
}
