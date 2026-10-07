import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../resource_labels.dart';
import 'resource_type_sheet.dart';

/// The selected resource type, with a change action while creating.
class ResourceTypeHeader extends StatelessWidget {
  const ResourceTypeHeader({
    super.key,
    required this.type,
    required this.limits,
    required this.onChanged,
  });

  final ResourceType type;
  final ResourceUploadLimits? limits;

  /// Null hides the change action, for example while editing.
  final ValueChanged<ResourceType>? onChanged;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Row(
      children: [
        ResourceTypeIcon(type: type),
        const SizedBox(width: TelmizoSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.resource_form_selected_type.tr(),
                style: context.textTheme.labelMedium?.copyWith(
                  color: TelmizoColors.onSurfaceVariant,
                ),
              ),
              Text(type.label, style: context.textTheme.titleMedium),
            ],
          ),
        ),
        if (onChanged case final onChanged?)
          TextButton(
            key: const Key('resource-change-type'),
            onPressed: () async {
              final picked = await showResourceTypeSheet(
                context,
                limits: limits,
              );
              if (picked != null && picked != type) onChanged(picked);
            },
            child: Text(LocaleKeys.resource_form_change_type.tr()),
          ),
      ],
    ),
  );
}
