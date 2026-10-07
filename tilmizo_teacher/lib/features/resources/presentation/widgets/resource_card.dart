import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../core/formatting/byte_size.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../classes/presentation/formatting/session_formatting.dart';
import '../resource_labels.dart';

enum ResourceCardAction { edit, delete }

/// One resource in the teacher list: type, size or host, title, linked
/// session, and open, edit and delete actions.
class ResourceCard extends StatelessWidget {
  const ResourceCard({
    super.key,
    required this.resource,
    required this.sessionLabel,
    required this.canManage,
    required this.downloadProgress,
    required this.onOpen,
    required this.onCancelDownload,
    required this.onAction,
  });

  final GroupResource resource;

  /// The linked session's label, or null when not linked or unknown.
  final String? sessionLabel;
  final bool canManage;
  final double? downloadProgress;
  final VoidCallback onOpen;
  final VoidCallback onCancelDownload;
  final ValueChanged<ResourceCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final type = resource.type;
    final detail = type.isLink
        ? resource.linkHost
        : resource.fileSize == null
        ? null
        : formatByteSize(resource.fileSize!);
    return TelmizoCard(
      key: Key('resource-${resource.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResourceThumbnail(resource: resource),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: TelmizoSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TelmizoPill(
                          label: type.label,
                          background: type.tint,
                          foreground: type.onTint,
                        ),
                        if (detail != null)
                          Text(
                            detail,
                            textDirection: type.isLink
                                ? TextDirection.ltr
                                : null,
                            style: textTheme.labelMedium?.copyWith(
                              color: TelmizoColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: TelmizoSpacing.xs),
                    Text(resource.title, style: textTheme.titleMedium),
                  ],
                ),
              ),
              if (canManage) _ActionsMenu(onAction: onAction),
            ],
          ),
          if (resource.description case final description?) ...[
            const SizedBox(height: TelmizoSpacing.sm),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TelmizoSpacing.md),
          _MetaStrip(
            sessionLabel: sessionLabel,
            hasSession: resource.sessionId != null,
            addedOn: context.cairoShortDate(resource.createdAt),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          ResourceOpenButton(
            isLink: type.isLink,
            progress: downloadProgress,
            openLabel: type.isLink
                ? LocaleKeys.resources_open_link.tr()
                : LocaleKeys.resources_open.tr(),
            progressLabel: (percent) =>
                LocaleKeys.resources_downloading.tr(args: [percent]),
            cancelLabel: LocaleKeys.resources_cancel_download.tr(),
            onOpen: onOpen,
            onCancel: onCancelDownload,
          ),
        ],
      ),
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({required this.onAction});

  final ValueChanged<ResourceCardAction> onAction;

  @override
  Widget build(BuildContext context) => PopupMenuButton<ResourceCardAction>(
    tooltip: LocaleKeys.resources_more_actions.tr(),
    onSelected: onAction,
    itemBuilder: (context) => [
      PopupMenuItem(
        value: ResourceCardAction.edit,
        child: ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(LocaleKeys.resources_edit.tr()),
        ),
      ),
      PopupMenuItem(
        value: ResourceCardAction.delete,
        child: ListTile(
          leading: const Icon(Icons.delete_outline, color: TelmizoColors.error),
          title: Text(
            LocaleKeys.resources_delete.tr(),
            style: const TextStyle(color: TelmizoColors.error),
          ),
        ),
      ),
    ],
  );
}

class _MetaStrip extends StatelessWidget {
  const _MetaStrip({
    required this.sessionLabel,
    required this.hasSession,
    required this.addedOn,
  });

  final String? sessionLabel;
  final bool hasSession;
  final String addedOn;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelMedium?.copyWith(
      color: TelmizoColors.onSurfaceVariant,
    );
    return Container(
      padding: const EdgeInsets.all(TelmizoSpacing.sm),
      decoration: BoxDecoration(
        color: TelmizoColors.surfaceContainerLow,
        borderRadius: TelmizoRadius.mdAll,
      ),
      child: Wrap(
        spacing: TelmizoSpacing.md,
        runSpacing: TelmizoSpacing.xs,
        children: [
          _Meta(
            icon: hasSession ? Icons.link : Icons.link_off,
            text: hasSession && sessionLabel != null
                ? LocaleKeys.resources_session_linked.tr(args: [sessionLabel!])
                : LocaleKeys.resources_session_none.tr(),
            style: hasSession
                ? style?.copyWith(color: TelmizoColors.primary)
                : style,
          ),
          _Meta(
            icon: Icons.schedule,
            text: LocaleKeys.resources_added_on.tr(args: [addedOn]),
            style: style,
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.style});

  final IconData icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: style?.color),
      const SizedBox(width: TelmizoSpacing.xs),
      Flexible(child: Text(text, style: style)),
    ],
  );
}
