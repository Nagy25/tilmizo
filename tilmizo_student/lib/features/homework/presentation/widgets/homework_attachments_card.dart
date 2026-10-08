import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../resources/presentation/controllers/student_resources_providers.dart';
import '../../../resources/presentation/resource_labels.dart';
import '../controllers/student_homework_providers.dart';

/// Attached files, opened through the private Resource downloader after the
/// backend re-confirms this session's access.
class HomeworkAttachmentsCard extends ConsumerWidget {
  const HomeworkAttachmentsCard({
    super.key,
    required this.homeworkKey,
    required this.homework,
  });

  final GroupHomeworkKey homeworkKey;
  final Homework homework;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    GroupResource resource,
  ) async {
    final failure = await ref
        .read(resourceDownloadsProvider.notifier)
        .open(
          resource,
          authorize: () => confirmResourceAccess(ref, homeworkKey.groupId),
        );
    if (failure == null || !context.mounted) return;
    showTelmizoSnackBar(context, resourceOpenFailureMessage(failure));
    if (failure == ResourceFileFailureType.denied) {
      refreshStudentHomework(ref, homeworkKey.groupId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(
      studentHomeworkAttachmentsProvider(homeworkKey),
    );
    final downloads = ref.watch(resourceDownloadsProvider);
    return TelmizoCard(
      key: const Key('student-homework-attachments'),
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
            ...switch (attachments) {
              AsyncData(:final value) => [
                for (final resource in value)
                  ListTile(
                    key: Key('homework-file-${resource.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: ResourceThumbnail(resource: resource, size: 40),
                    title: Text(resource.title),
                    subtitle: Text(switch (downloads[resource.id]) {
                      final progress? => LocaleKeys.resources_downloading.tr(
                        args: ['${(progress * 100).round()}'],
                      ),
                      null => resource.type.label,
                    }),
                    trailing: switch (downloads[resource.id]) {
                      final progress? => IconButton(
                        tooltip: LocaleKeys.resources_cancel_download.tr(),
                        onPressed: () => ref
                            .read(resourceDownloadsProvider.notifier)
                            .cancel(resource.id),
                        icon: CircularProgressIndicator(value: progress),
                      ),
                      null => const Icon(Icons.download_outlined),
                    },
                    onTap: downloads.containsKey(resource.id)
                        ? null
                        : () => _open(context, ref, resource),
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
                    studentHomeworkAttachmentsProvider(homeworkKey),
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
