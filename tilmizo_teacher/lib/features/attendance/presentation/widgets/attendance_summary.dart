import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../classes/domain/class_session.dart';
import '../../../classes/presentation/formatting/session_formatting.dart';
import 'attendance_status_style.dart';

/// Session context and live counts of the displayed marks.
class AttendanceSummary extends StatelessWidget {
  const AttendanceSummary({
    super.key,
    required this.session,
    required this.total,
    required this.counts,
    this.filter,
    this.onFilter,
  });

  final ClassSession session;
  final int total;
  final Map<AttendanceStatus, int> counts;

  /// The status the list is filtered by; null shows everyone.
  final AttendanceStatus? filter;
  final ValueChanged<AttendanceStatus?>? onFilter;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final onFilter = this.onFilter;
    return TelmizoCard(
      padding: const EdgeInsets.all(TelmizoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(session.group.name, style: textTheme.titleMedium),
          Text(
            [
              ?session.group.subject,
              context.cairoDate(session.startsAt),
              context.sessionTimeRange(session),
            ].join(' • '),
            style: textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          Wrap(
            spacing: TelmizoSpacing.sm,
            runSpacing: TelmizoSpacing.sm,
            children: [
              FilterChip(
                key: const Key('attendance-filter-all'),
                label: Text(
                  '${LocaleKeys.attendance_filter_all.tr()} ($total)',
                ),
                selected: filter == null,
                onSelected: onFilter == null ? null : (_) => onFilter(null),
              ),
              for (final status in AttendanceStatus.values)
                FilterChip(
                  key: Key('attendance-filter-${status.backendValue}'),
                  avatar: Icon(status.icon, size: 16, color: status.color),
                  label: Text('${status.label} (${counts[status] ?? 0})'),
                  selected: filter == status,
                  selectedColor: status.container,
                  showCheckmark: false,
                  onSelected: onFilter == null
                      ? null
                      : (_) => onFilter(filter == status ? null : status),
                ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          Text(
            LocaleKeys.attendance_unmarked_note.tr(),
            style: textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
