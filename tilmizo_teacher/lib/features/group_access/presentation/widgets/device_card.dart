import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/student_device.dart';
import 'access_labels.dart';

/// Device name and platform, with the privacy note about what is collected.
class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key, required this.title, required this.device});

  final String title;
  final StudentDevice? device;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final device = this.device;
    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.lg),
      decoration: const BoxDecoration(
        color: TelmizoColors.surfaceContainerLow,
        borderRadius: TelmizoRadius.xlAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          if (device == null)
            Text(
              LocaleKeys.access_no_approved_device.tr(),
              style: textTheme.bodyMedium,
            )
          else
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: TelmizoColors.surfaceContainerLowest,
                  foregroundColor: TelmizoColors.primary,
                  child: Icon(platformIcon(device.platform)),
                ),
                const SizedBox(width: TelmizoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.name, style: textTheme.titleMedium),
                      Text(
                        platformLabel(device.platform),
                        style: textTheme.bodySmall?.copyWith(
                          color: TelmizoColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: TelmizoSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                size: 16,
                color: TelmizoColors.onSurfaceVariant,
              ),
              const SizedBox(width: TelmizoSpacing.xs),
              Expanded(
                child: Text(
                  LocaleKeys.access_device_privacy.tr(),
                  style: textTheme.bodySmall?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
