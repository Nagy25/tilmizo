import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/session_location.dart';

/// Icon, type, and address or link of a session location.
class SessionLocationLine extends StatelessWidget {
  const SessionLocationLine({super.key, required this.location});

  final SessionLocation location;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          location.isOnline
              ? Icons.videocam_outlined
              : Icons.apartment_outlined,
          size: 20,
          color: TelmizoColors.onSurfaceVariant,
        ),
        const SizedBox(width: TelmizoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (location.isOnline
                        ? LocaleKeys.location_online
                        : LocaleKeys.location_physical)
                    .tr(),
                style: textTheme.labelMedium?.copyWith(
                  color: TelmizoColors.onSurfaceVariant,
                ),
              ),
              Text(
                location.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textDirection: location.isOnline ? TextDirection.ltr : null,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
