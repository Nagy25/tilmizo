import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/formatting/byte_size.dart';
import '../../../../generated/locale_keys.g.dart';
import '../resource_labels.dart';

/// A read-only resource with authenticated open, progress and retry. It
/// carries no add, edit, delete, offline or device-protection controls.
class StudentResourceCard extends StatelessWidget {
  const StudentResourceCard({
    super.key,
    required this.resource,
    required this.sessionLabel,
    required this.downloadProgress,
    required this.failure,
    required this.onOpen,
    required this.onCancel,
  });

  final GroupResource resource;
  final String? sessionLabel;
  final double? downloadProgress;
  final ResourceFileFailureType? failure;
  final VoidCallback onOpen;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: TelmizoColors.onSurfaceVariant,
    );
    final type = resource.type;
    final details = [
      type.label,
      if (resource.fileSize case final size?) formatByteSize(size),
      ?resource.linkHost,
    ].join(' • ');
    return TelmizoCard(
      key: Key('student-resource-${resource.id}'),
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
                    Text(resource.title, style: textTheme.titleMedium),
                    const SizedBox(height: TelmizoSpacing.xs),
                    Text(details, style: muted),
                    const SizedBox(height: TelmizoSpacing.xs),
                    TelmizoPill(
                      icon: resource.sessionId == null
                          ? Icons.groups_outlined
                          : Icons.event_outlined,
                      label: resource.sessionId == null
                          ? LocaleKeys.resources_session_none.tr()
                          : sessionLabel == null
                          ? LocaleKeys.resources_session_linked.tr(args: ['…'])
                          : LocaleKeys.resources_session_linked.tr(
                              args: [sessionLabel!],
                            ),
                      background: TelmizoColors.surfaceContainerLow,
                      foreground: TelmizoColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (resource.description case final description?) ...[
            const SizedBox(height: TelmizoSpacing.sm),
            Text(description, style: muted),
          ],
          if (failure case final failure?) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(message: resourceOpenFailureMessage(failure)),
          ],
          const SizedBox(height: TelmizoSpacing.md),
          ResourceOpenButton(
            isLink: type.isLink,
            progress: downloadProgress,
            openLabel: failure != null
                ? LocaleKeys.common_retry.tr()
                : type.isLink
                ? LocaleKeys.resources_open_link.tr()
                : LocaleKeys.resources_open.tr(),
            progressLabel: (percent) =>
                LocaleKeys.resources_downloading.tr(args: [percent]),
            cancelLabel: LocaleKeys.resources_cancel_download.tr(),
            onOpen: onOpen,
            onCancel: onCancel,
          ),
        ],
      ),
    );
  }
}
