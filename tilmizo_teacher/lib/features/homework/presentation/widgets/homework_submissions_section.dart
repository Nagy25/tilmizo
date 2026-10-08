import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../controllers/homework_providers.dart';
import '../homework_labels.dart';

/// Students' saved links for link-type homework, read-only.
class HomeworkSubmissionsSection extends ConsumerWidget {
  const HomeworkSubmissionsSection({super.key, required this.homeworkId});

  final String homeworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = ref.watch(homeworkSubmissionsProvider(homeworkId));
    final textTheme = context.textTheme;
    return TelmizoCard(
      key: const Key('homework-submissions'),
      // List tiles paint ink on the nearest Material, not on the card.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.homework_submissions_title.tr(),
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            ...switch (submissions) {
              AsyncData(:final value) when value.isEmpty => [
                Text(LocaleKeys.homework_submissions_none.tr()),
              ],
              AsyncData(:final value) => [
                for (final item in value)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link),
                    title: Text(
                      item.studentName ??
                          LocaleKeys.homework_submission_unknown_student.tr(),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          item.submission.url,
                          textDirection: TextDirection.ltr,
                        ),
                        Text(
                          LocaleKeys.homework_submission_updated.tr(
                            args: [
                              context.homeworkInstant(
                                item.submission.updatedAt,
                              ),
                            ],
                          ),
                          style: textTheme.labelSmall,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: LocaleKeys.homework_submission_copy.tr(),
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: item.submission.url),
                        );
                        if (context.mounted) {
                          showTelmizoSnackBar(
                            context,
                            LocaleKeys.homework_link_copied.tr(),
                          );
                        }
                      },
                    ),
                  ),
              ],
              AsyncError() => [
                Text(LocaleKeys.homework_submissions_load_error.tr()),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(homeworkSubmissionsProvider(homeworkId)),
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
