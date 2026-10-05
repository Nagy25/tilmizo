import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// A non-interactive preview until the classes flow is implemented.
class ClassesPlaceholderTile extends StatelessWidget {
  const ClassesPlaceholderTile({super.key});

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Row(
      children: [
        const Icon(
          Icons.event_available_outlined,
          color: TelmizoColors.primary,
        ),
        const SizedBox(width: TelmizoSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.classes_title.tr(),
                style: context.textTheme.titleMedium,
              ),
              Text(
                LocaleKeys.classes_coming_soon.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: TelmizoColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
