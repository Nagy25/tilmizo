import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/attendance_roster.dart';
import 'attendance_status_style.dart';

enum AttendanceMode { quick, detailed }

/// One student with their current mark and the controls of [mode].
class AttendanceStudentRow extends StatelessWidget {
  const AttendanceStudentRow({
    super.key,
    required this.student,
    required this.status,
    required this.mode,
    required this.onChanged,
    this.isUnsaved = false,
    this.hasFailed = false,
  });

  final AttendanceStudent student;
  final AttendanceStatus status;
  final AttendanceMode mode;

  /// Null when the sheet is read-only.
  final ValueChanged<AttendanceStatus>? onChanged;
  final bool isUnsaved;
  final bool hasFailed;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return TelmizoCard(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      borderRadius: TelmizoRadius.lgAll,
      color: hasFailed
          ? TelmizoColors.errorContainer
          : TelmizoColors.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: TelmizoColors.secondaryContainer,
                foregroundColor: TelmizoColors.onSecondaryContainer,
                child: Text(student.displayName.characters.first),
              ),
              const SizedBox(width: TelmizoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.displayName, style: textTheme.titleSmall),
                    if (hasFailed || isUnsaved)
                      Text(
                        (hasFailed
                                ? LocaleKeys.attendance_row_failed
                                : LocaleKeys.attendance_unsaved_badge)
                            .tr(),
                        style: textTheme.labelSmall?.copyWith(
                          color: hasFailed
                              ? TelmizoColors.error
                              : TelmizoColors.tertiary,
                        ),
                      ),
                  ],
                ),
              ),
              if (mode == AttendanceMode.quick || onChanged == null)
                AttendanceStatusPill(status: status),
            ],
          ),
          if (onChanged case final onChanged?) ...[
            const SizedBox(height: TelmizoSpacing.sm),
            mode == AttendanceMode.detailed
                ? _StatusChoices(
                    statuses: AttendanceStatus.values,
                    selected: status,
                    onChanged: onChanged,
                    studentId: student.studentId,
                  )
                : _StatusChoices(
                    statuses: const [
                      AttendanceStatus.present,
                      AttendanceStatus.absent,
                    ],
                    selected: status,
                    onChanged: onChanged,
                    studentId: student.studentId,
                  ),
          ],
        ],
      ),
    );
  }
}

class _StatusChoices extends StatelessWidget {
  const _StatusChoices({
    required this.statuses,
    required this.selected,
    required this.onChanged,
    required this.studentId,
  });

  final List<AttendanceStatus> statuses;
  final AttendanceStatus selected;
  final ValueChanged<AttendanceStatus> onChanged;
  final String studentId;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: TelmizoSpacing.sm,
    runSpacing: TelmizoSpacing.xs,
    children: [
      for (final status in statuses)
        ChoiceChip(
          key: Key('mark-$studentId-${status.backendValue}'),
          avatar: Icon(
            status.icon,
            size: 18,
            color: status == selected ? TelmizoColors.onPrimary : status.color,
          ),
          showCheckmark: false,
          label: Text(status.label),
          selected: status == selected,
          selectedColor: status.color,
          labelStyle: TextStyle(
            color: status == selected ? TelmizoColors.onPrimary : status.color,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onChanged(status),
        ),
    ],
  );
}
