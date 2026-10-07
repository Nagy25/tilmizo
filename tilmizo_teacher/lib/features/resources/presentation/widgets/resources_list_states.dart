import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../resource_labels.dart';

class ResourcesLoading extends StatelessWidget {
  const ResourcesLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(TelmizoSpacing.xl),
    child: Center(child: CircularProgressIndicator()),
  );
}

class ResourcesLoadError extends StatelessWidget {
  const ResourcesLoadError({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Message(
    icon: Icons.cloud_off_outlined,
    title: LocaleKeys.resources_load_error_title.tr(),
    body: resourceFailureMessage(error),
    actionLabel: LocaleKeys.common_retry.tr(),
    onAction: onRetry,
  );
}

/// No resources at all. RLS-hidden rows look the same as none.
class ResourcesEmptyView extends StatelessWidget {
  const ResourcesEmptyView({
    super.key,
    required this.canAdd,
    required this.onAdd,
  });

  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => _Message(
    key: const Key('resources-empty'),
    icon: Icons.folder_open_outlined,
    title: LocaleKeys.resources_empty_title.tr(),
    body: canAdd
        ? LocaleKeys.resources_empty_body.tr()
        : LocaleKeys.resources_empty_archived_body.tr(),
    actionLabel: canAdd ? LocaleKeys.resources_add.tr() : null,
    onAction: canAdd ? onAdd : null,
  );
}

class ResourcesNoMatches extends StatelessWidget {
  const ResourcesNoMatches({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => _Message(
    icon: Icons.search_off,
    title: LocaleKeys.resources_no_matches.tr(),
    actionLabel: LocaleKeys.resources_clear_filters.tr(),
    onAction: onClear,
  );
}

class ResourcesLoadMore extends StatelessWidget {
  const ResourcesLoadMore({
    super.key,
    required this.isLoading,
    required this.failed,
    required this.onPressed,
  });

  final bool isLoading;
  final bool failed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (failed)
        Padding(
          padding: const EdgeInsets.only(bottom: TelmizoSpacing.sm),
          child: Text(
            LocaleKeys.resources_load_more_error.tr(),
            style: const TextStyle(color: TelmizoColors.error),
          ),
        ),
      TelmizoSecondaryButton(
        key: const Key('resources-load-more'),
        label: LocaleKeys.resources_load_more.tr(),
        isLoading: isLoading,
        onPressed: isLoading ? null : onPressed,
      ),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Column(
      children: [
        Icon(icon, size: 40, color: TelmizoColors.onSurfaceVariant),
        const SizedBox(height: TelmizoSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium,
        ),
        if (body != null) ...[
          const SizedBox(height: TelmizoSpacing.xs),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: TelmizoSpacing.md),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}
