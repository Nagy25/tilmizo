import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/attendance_roster.dart';
import '../controllers/attendance_controller.dart';
import 'attendance_student_row.dart';
import 'attendance_summary.dart';

/// The roster list with filters, search, and per-student controls.
class AttendanceSheetView extends StatefulWidget {
  const AttendanceSheetView({
    super.key,
    required this.sheet,
    required this.mode,
    required this.onModeChanged,
    required this.onStatusChanged,
    required this.onMarkUnmarkedPresent,
    this.readOnlyReason,
  });

  final AttendanceSheet sheet;
  final AttendanceMode mode;
  final ValueChanged<AttendanceMode> onModeChanged;
  final void Function(String studentId, AttendanceStatus status)
  onStatusChanged;
  final VoidCallback onMarkUnmarkedPresent;

  /// Why marks cannot be changed; null when the sheet is editable.
  final String? readOnlyReason;

  @override
  State<AttendanceSheetView> createState() => _AttendanceSheetViewState();
}

class _AttendanceSheetViewState extends State<AttendanceSheetView> {
  final _search = TextEditingController();
  AttendanceStatus? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AttendanceStudent student) {
    final sheet = widget.sheet;
    final filter = _filter;
    if (filter != null && sheet.statusOf(student.studentId) != filter) {
      return false;
    }
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return (student.studentName?.toLowerCase().contains(query) ?? false) ||
        student.studentPhone.contains(query);
  }

  Widget _row(AttendanceStudent student) {
    final sheet = widget.sheet;
    final id = student.studentId;
    final editable = widget.readOnlyReason == null && !sheet.isSaving;
    return Padding(
      padding: const EdgeInsets.only(bottom: TelmizoSpacing.sm),
      child: AttendanceStudentRow(
        key: ValueKey(id),
        student: student,
        status: sheet.statusOf(id),
        mode: widget.mode,
        isUnsaved: sheet.pending.containsKey(id),
        hasFailed: sheet.failed.contains(id),
        onChanged: editable
            ? (status) => widget.onStatusChanged(id, status)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    final roster = sheet.roster;
    final readOnlyReason = widget.readOnlyReason;
    final editable = readOnlyReason == null;
    final current = roster.current.where(_matches).toList();
    final former = roster.former.where(_matches).toList();
    final textTheme = context.textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TelmizoSpacing.margin,
        TelmizoSpacing.lg,
        TelmizoSpacing.margin,
        TelmizoSpacing.xl,
      ),
      children: [
        if (readOnlyReason != null) ...[
          TelmizoInlineMessage(
            message: readOnlyReason,
            tone: TelmizoMessageTone.info,
          ),
          const SizedBox(height: TelmizoSpacing.md),
        ],
        AttendanceSummary(
          session: sheet.session,
          total: roster.current.length,
          counts: sheet.counts,
          filter: _filter,
          onFilter: (status) => setState(() => _filter = status),
        ),
        const SizedBox(height: TelmizoSpacing.md),
        if (editable) ...[
          SegmentedButton<AttendanceMode>(
            segments: [
              ButtonSegment(
                value: AttendanceMode.quick,
                icon: const Icon(Icons.bolt),
                label: Text(LocaleKeys.attendance_mode_quick.tr()),
              ),
              ButtonSegment(
                value: AttendanceMode.detailed,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(LocaleKeys.attendance_mode_detailed.tr()),
              ),
            ],
            selected: {widget.mode},
            onSelectionChanged: (modes) => widget.onModeChanged(modes.single),
          ),
          const SizedBox(height: TelmizoSpacing.md),
        ],
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: LocaleKeys.attendance_search_hint.tr(),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        if (editable && roster.current.isNotEmpty) ...[
          const SizedBox(height: TelmizoSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('mark-unmarked-present'),
              onPressed: sheet.isSaving ? null : widget.onMarkUnmarkedPresent,
              icon: const Icon(Icons.done_all),
              label: Text(LocaleKeys.attendance_mark_unmarked_present.tr()),
            ),
          ),
        ],
        const SizedBox(height: TelmizoSpacing.md),
        if (roster.current.isEmpty)
          TelmizoInlineMessage(
            title: LocaleKeys.attendance_empty_title.tr(),
            message: LocaleKeys.attendance_empty_body.tr(),
            tone: TelmizoMessageTone.info,
          )
        else if (current.isEmpty && former.isEmpty)
          Padding(
            padding: const EdgeInsets.all(TelmizoSpacing.lg),
            child: Text(
              LocaleKeys.attendance_no_results.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ),
        ...current.map(_row),
        if (former.isNotEmpty) ...[
          const SizedBox(height: TelmizoSpacing.lg),
          Text(
            LocaleKeys.attendance_former_title.tr(),
            style: textTheme.titleMedium,
          ),
          Text(
            LocaleKeys.attendance_former_body.tr(),
            style: textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          ...former.map(_row),
        ],
      ],
    );
  }
}
