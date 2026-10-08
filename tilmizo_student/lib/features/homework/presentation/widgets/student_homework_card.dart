import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../homework_labels.dart';

/// One homework in a list. There is no status, grade or completion mark.
class StudentHomeworkCard extends StatelessWidget {
  const StudentHomeworkCard({
    super.key,
    required this.homework,
    required this.onTap,
  });

  final Homework homework;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final files = homework.attachments.length;
    return TelmizoCard(
      key: Key('student-homework-${homework.id}'),
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: TelmizoRadius.xlAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(TelmizoSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: TelmizoColors.primaryTint,
                      foregroundColor: TelmizoColors.primary,
                      child: Icon(Icons.assignment_outlined),
                    ),
                    const SizedBox(width: TelmizoSpacing.md),
                    Expanded(
                      child: Text(
                        context.homeworkHeading(homework),
                        style: textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: TelmizoSpacing.sm),
                Text(
                  context.homeworkPreview(homework),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: TelmizoSpacing.md),
                Wrap(
                  spacing: TelmizoSpacing.sm,
                  runSpacing: TelmizoSpacing.xs,
                  children: [
                    _pill(
                      homework.submissionType.icon,
                      homework.submissionType.label,
                    ),
                    _pill(Icons.event_outlined, context.homeworkDue(homework)),
                    if (files > 0)
                      _pill(
                        Icons.attach_file,
                        LocaleKeys.homework_files_count.plural(files),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label) => TelmizoPill(
    icon: icon,
    label: label,
    background: TelmizoColors.surfaceContainerLow,
    foreground: TelmizoColors.onSurfaceVariant,
  );
}
