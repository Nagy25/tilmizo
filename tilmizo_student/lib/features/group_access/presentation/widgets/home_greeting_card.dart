import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../profile/presentation/controllers/current_profile_controller.dart';
import '../controllers/group_access_providers.dart';

/// Greeting with the student's name, plus active-group and device tiles.
class HomeGreetingCard extends ConsumerWidget {
  const HomeGreetingCard({super.key, this.activeGroups});

  /// Hidden on the empty screen.
  final int? activeGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final device = ref.watch(deviceDisplayInfoProvider).value;
    final textTheme = context.textTheme;
    final firstName = profile?.firstName;

    return TelmizoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: TelmizoColors.primaryFixed,
                foregroundColor: TelmizoColors.primaryPressed,
                child: firstName == null
                    ? const Icon(Icons.person_outline)
                    : Text(
                        firstName.characters.first,
                        style: textTheme.headlineSmall,
                      ),
              ),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName == null
                          ? LocaleKeys.home_greeting_fallback.tr()
                          : LocaleKeys.home_greeting.tr(args: [firstName]),
                      style: textTheme.headlineSmall,
                    ),
                    Text(
                      LocaleKeys.home_greeting_subtitle.tr(),
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
            children: [
              if (activeGroups case final count?) ...[
                Expanded(
                  child: _StatTile(
                    icon: Icons.groups_outlined,
                    label: LocaleKeys.stat_active_groups.tr(),
                    value: '$count',
                  ),
                ),
                const SizedBox(width: TelmizoSpacing.sm),
              ],
              Expanded(
                child: _StatTile(
                  icon: device?.platform == DevicePlatform.ios
                      ? Icons.phone_iphone
                      : Icons.devices_outlined,
                  label: LocaleKeys.stat_this_device.tr(),
                  value: device?.name ?? '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      decoration: const BoxDecoration(
        color: TelmizoColors.surfaceContainerLow,
        borderRadius: TelmizoRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(icon, color: TelmizoColors.primary),
          const SizedBox(width: TelmizoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: TelmizoColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
