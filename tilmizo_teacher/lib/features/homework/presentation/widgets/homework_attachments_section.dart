import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../resources/presentation/resource_labels.dart';
import '../controllers/homework_providers.dart';

/// The attached Resource files, opened through the private downloader.
class HomeworkAttachmentsSection extends ConsumerWidget {
  const HomeworkAttachmentsSection({super.key, required this.homework});

  final Homework homework;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    GroupResource resource,
  ) async {
    final failure = await ref
        .read(resourceDownloadsProvider.notifier)
        .open(resource);
    if (failure != null && context.mounted) {
      showTelmizoSnackBar(context, resourceOpenFailureMessage(failure));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(homeworkAttachmentsProvider(homework.id));
    final downloads = ref.watch(resourceDownloadsProvider);
    return TelmizoCard(
      key: const Key('homework-attachments'),
      // List tiles paint ink on the nearest Material, not on the card.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.homework_attachments_title.tr(),
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            if (homework.attachments.isEmpty)
              Text(LocaleKeys.homework_attachments_none.tr())
            else
              ...switch (attachments) {
                AsyncData(:final value) => [
                  for (final resource in value)
                    ListTile(
                      key: Key('homework-attachment-${resource.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: ResourceThumbnail(resource: resource, size: 40),
                      title: Text(resource.title),
                      subtitle: Text(resource.type.label),
                      trailing: switch (downloads[resource.id]) {
                        final progress? => SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(value: progress),
                        ),
                        null => IconButton(
                          tooltip: LocaleKeys.resources_open.tr(),
                          onPressed: () => _open(context, ref, resource),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                      },
                      onTap: () => _open(context, ref, resource),
                    ),
                  if (value.length < homework.attachments.length)
                    TelmizoInlineMessage(
                      message: LocaleKeys.homework_attachment_unavailable.tr(),
                      tone: TelmizoMessageTone.warning,
                    ),
                ],
                AsyncError() => [
                  Text(LocaleKeys.homework_attachments_load_error.tr()),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      homeworkAttachmentsProvider(homework.id),
                    ),
                    child: Text(LocaleKeys.common_retry.tr()),
                  ),
                ],
                _ => [const LinearProgressIndicator()],
              },
          ],
        ),
      ),
    );
  }
}
