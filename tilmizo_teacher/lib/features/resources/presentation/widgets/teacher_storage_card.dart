import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/byte_size.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../profile/presentation/controllers/resource_storage_usage_controller.dart';

/// Compact teacher-wide quota from `get_my_resource_storage_usage()`. The
/// quota spans all of the teacher's groups, so it is labelled as such.
class TeacherStorageCard extends ConsumerWidget {
  const TeacherStorageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(resourceStorageUsageProvider);
    final textTheme = context.textTheme;
    return TelmizoCard(
      key: const Key('teacher-storage-card'),
      child: switch (usage) {
        AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_outlined, color: TelmizoColors.primary),
                const SizedBox(width: TelmizoSpacing.sm),
                Expanded(
                  child: Text(
                    LocaleKeys.resource_storage_title.tr(),
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            Text(
              '${formatByteSize(value.usedBytes)} / '
              '${formatByteSize(value.quotaBytes)}',
              style: textTheme.labelLarge,
            ),
            const SizedBox(height: TelmizoSpacing.xs),
            LinearProgressIndicator(
              value: value.progress,
              minHeight: 8,
              borderRadius: TelmizoRadius.pillAll,
              backgroundColor: TelmizoColors.surfaceContainerHigh,
              color: TelmizoColors.primary,
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            Text(
              LocaleKeys.resources_storage_teacher_wide.tr(),
              style: textTheme.bodySmall?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AsyncError() => Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: TelmizoColors.error),
            const SizedBox(width: TelmizoSpacing.sm),
            Expanded(child: Text(LocaleKeys.resource_storage_load_error.tr())),
            TextButton(
              onPressed: () => ref.invalidate(resourceStorageUsageProvider),
              child: Text(LocaleKeys.common_retry.tr()),
            ),
          ],
        ),
        _ => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}
