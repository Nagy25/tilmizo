import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// A device's display name and platform. Never shows identifiers.
class DeviceInfoCard extends StatelessWidget {
  const DeviceInfoCard({
    super.key,
    required this.label,
    required this.deviceName,
    this.platform,
    this.isThisDevice = false,
  });

  final String label;
  final String deviceName;
  final DevicePlatform? platform;
  final bool isThisDevice;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      decoration: const BoxDecoration(
        color: TelmizoColors.surfaceContainer,
        borderRadius: TelmizoRadius.xlAll,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: TelmizoColors.surfaceContainerLowest,
            foregroundColor: TelmizoColors.primary,
            child: Icon(
              platform == DevicePlatform.ios
                  ? Icons.phone_iphone
                  : Icons.phone_android,
            ),
          ),
          const SizedBox(width: TelmizoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  isThisDevice
                      ? '$deviceName ${LocaleKeys.this_device.tr()}'
                      : deviceName,
                  style: textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
