import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/byte_size.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/teacher_resource_storage_usage.dart';
import '../controllers/resource_storage_usage_controller.dart';

class ResourceStorageUsageCard extends ConsumerWidget {
  const ResourceStorageUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(resourceStorageUsageProvider);
    return usage.when(
      loading: () =>
          const TelmizoCard(child: Center(child: CircularProgressIndicator())),
      error: (_, _) => TelmizoCard(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, color: TelmizoColors.error),
            const SizedBox(height: TelmizoSpacing.sm),
            Text(
              LocaleKeys.resource_storage_load_error.tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            TextButton.icon(
              onPressed: () => ref.invalidate(resourceStorageUsageProvider),
              icon: const Icon(Icons.refresh),
              label: Text(LocaleKeys.common_retry.tr()),
            ),
          ],
        ),
      ),
      data: (value) => _StorageUsageContent(usage: value),
    );
  }
}

class _StorageUsageContent extends StatelessWidget {
  const _StorageUsageContent({required this.usage});

  final TeacherResourceStorageUsage usage;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final percent = usage.usagePercent
        .clamp(0, 100)
        .toStringAsFixed(usage.usagePercent % 1 == 0 ? 0 : 1);
    return TelmizoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_outlined, color: TelmizoColors.primary),
              const SizedBox(width: TelmizoSpacing.sm),
              Expanded(
                child: Text(
                  LocaleKeys.resource_storage_title.tr(),
                  style: textTheme.titleLarge,
                ),
              ),
              TelmizoPill(
                label: usage.planKey == 'default'
                    ? LocaleKeys.resource_storage_free_plan.tr()
                    : LocaleKeys.resource_storage_plan.tr(
                        args: [usage.planKey],
                      ),
                background: TelmizoColors.secondaryContainer,
                foreground: TelmizoColors.onSecondaryContainer,
              ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            LocaleKeys.resource_storage_subtitle.tr(),
            style: textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${LocaleKeys.resource_storage_used.tr()}: '
                  '${formatByteSize(usage.usedBytes)}',
                  style: textTheme.titleSmall,
                ),
              ),
              Text(
                LocaleKeys.resource_storage_percent.tr(args: [percent]),
                style: textTheme.labelLarge?.copyWith(
                  color: TelmizoColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          LinearProgressIndicator(
            value: usage.progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: TelmizoColors.surfaceContainerHigh,
            color: TelmizoColors.primary,
          ),
          const SizedBox(height: TelmizoSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: LocaleKeys.resource_storage_total.tr(),
                  value: formatByteSize(usage.quotaBytes),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: LocaleKeys.resource_storage_remaining.tr(),
                  value: formatByteSize(usage.remainingBytes),
                ),
              ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: TelmizoSpacing.md),
          Text(
            LocaleKeys.resource_storage_limits_title.tr(),
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          _LimitRow(
            icon: Icons.picture_as_pdf_outlined,
            label: LocaleKeys.resource_storage_pdf_file.tr(),
            value: formatByteSize(usage.pdfFileMaxBytes),
          ),
          _LimitRow(
            icon: Icons.image_outlined,
            label: LocaleKeys.resource_storage_image.tr(),
            value: formatByteSize(usage.imageMaxBytes),
          ),
          _LimitRow(
            icon: Icons.video_file_outlined,
            label: LocaleKeys.resource_storage_video.tr(),
            value: formatByteSize(usage.videoMaxBytes),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(
          color: TelmizoColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: TelmizoSpacing.xs),
      Text(value, style: context.textTheme.titleMedium),
    ],
  );
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TelmizoSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 20, color: TelmizoColors.onSurfaceVariant),
        const SizedBox(width: TelmizoSpacing.sm),
        Expanded(child: Text(label)),
        Text(value, style: context.textTheme.labelLarge),
      ],
    ),
  );
}
