import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../classes/domain/class_session.dart';
import '../../../classes/presentation/controllers/classes_providers.dart';
import '../../data/attendance_repository_impl.dart';
import '../../domain/attendance_roster.dart';

/// The result of the last save: how many marks were stored or failed.
typedef AttendanceSaveResult = ({int saved, int failed});

@immutable
final class AttendanceSheet {
  const AttendanceSheet({
    required this.session,
    required this.roster,
    required this.saved,
    this.pending = const {},
    this.failed = const {},
    this.isSaving = false,
    this.lastResult,
  });

  final ClassSession session;
  final AttendanceRoster roster;

  /// Stored marks by student id; missing means not marked.
  final Map<String, AttendanceStatus> saved;

  /// Unsaved marks the teacher chose, by student id.
  final Map<String, AttendanceStatus> pending;

  /// Students whose last save attempt failed; their marks stay pending.
  final Set<String> failed;
  final bool isSaving;
  final AttendanceSaveResult? lastResult;

  AttendanceStatus statusOf(String studentId) =>
      pending[studentId] ?? saved[studentId] ?? AttendanceStatus.notMarked;

  bool get hasChanges => pending.isNotEmpty;

  /// Counts of current students by their displayed status.
  Map<AttendanceStatus, int> get counts {
    final counts = {for (final status in AttendanceStatus.values) status: 0};
    for (final student in roster.current) {
      counts.update(statusOf(student.studentId), (count) => count + 1);
    }
    return counts;
  }

  AttendanceSheet copyWith({
    Map<String, AttendanceStatus>? saved,
    Map<String, AttendanceStatus>? pending,
    Set<String>? failed,
    bool? isSaving,
    AttendanceSaveResult? Function()? lastResult,
  }) => AttendanceSheet(
    session: session,
    roster: roster,
    saved: saved ?? this.saved,
    pending: pending ?? this.pending,
    failed: failed ?? this.failed,
    isSaving: isSaving ?? this.isSaving,
    lastResult: lastResult == null ? this.lastResult : lastResult(),
  );
}

final attendanceControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AttendanceController, AttendanceSheet, String>(
      AttendanceController.new,
    );

/// Teacher-marked attendance for one session.
///
/// Only marks the teacher explicitly chose are saved, one student at a time
/// through `set_session_attendance`. Unmarked students are never turned into
/// absences.
class AttendanceController extends AsyncNotifier<AttendanceSheet> {
  AttendanceController(this.sessionId);

  /// Concurrent writes per batch while saving.
  static const batchSize = 5;

  final String sessionId;

  @override
  Future<AttendanceSheet> build() async {
    final session = await ref.watch(sessionDetailsProvider(sessionId).future);
    final roster = await ref
        .watch(attendanceRepositoryProvider)
        .fetchRoster(groupId: session.group.id, sessionId: sessionId);
    return AttendanceSheet(
      session: session,
      roster: roster,
      saved: {
        for (final student in roster.all)
          if (student.savedStatus != AttendanceStatus.notMarked)
            student.studentId: student.savedStatus,
      },
    );
  }

  AttendanceSheet? get _sheet => state.value;

  void setStatus(String studentId, AttendanceStatus status) {
    final sheet = _sheet;
    if (sheet == null || sheet.isSaving) return;
    final stored = sheet.saved[studentId] ?? AttendanceStatus.notMarked;
    final pending = {...sheet.pending};
    if (status == stored) {
      pending.remove(studentId);
    } else {
      pending[studentId] = status;
    }
    state = AsyncData(
      sheet.copyWith(
        pending: pending,
        failed: {...sheet.failed}..remove(studentId),
        lastResult: () => null,
      ),
    );
  }

  /// Marks every current student who is still unmarked as present. Students
  /// with any other mark are left unchanged.
  void markUnmarkedPresent() {
    final sheet = _sheet;
    if (sheet == null || sheet.isSaving) return;
    final pending = {...sheet.pending};
    for (final student in sheet.roster.current) {
      if (sheet.statusOf(student.studentId) == AttendanceStatus.notMarked) {
        pending[student.studentId] = AttendanceStatus.present;
      }
    }
    state = AsyncData(sheet.copyWith(pending: pending, lastResult: () => null));
  }

  void discardChanges() {
    final sheet = _sheet;
    if (sheet == null || sheet.isSaving) return;
    state = AsyncData(
      sheet.copyWith(
        pending: const {},
        failed: const {},
        lastResult: () => null,
      ),
    );
  }

  /// Saves every pending mark. Successful marks become saved; failed marks
  /// stay pending and are reported so the teacher can retry them.
  Future<AttendanceSaveResult?> save() async {
    final sheet = _sheet;
    if (sheet == null || sheet.isSaving || !sheet.hasChanges) return null;
    state = AsyncData(
      sheet.copyWith(isSaving: true, failed: const {}, lastResult: () => null),
    );

    final repository = ref.read(attendanceRepositoryProvider);
    final stored = <String, AttendanceStatus>{};
    final failed = <String>{};
    final entries = sheet.pending.entries.toList();
    for (var i = 0; i < entries.length; i += batchSize) {
      final batch = entries.skip(i).take(batchSize);
      await Future.wait([
        for (final entry in batch)
          repository
              .setAttendance(
                sessionId: sessionId,
                studentId: entry.key,
                status: entry.value,
              )
              .then<void>(
                (status) {
                  stored[entry.key] = status;
                },
                onError: (Object _) {
                  failed.add(entry.key);
                },
              ),
      ]);
      if (!ref.mounted) return null;
    }

    final saved = {...sheet.saved, ...stored}
      ..removeWhere((_, status) => status == AttendanceStatus.notMarked);
    final current = _sheet ?? sheet;
    final pending = {...current.pending}
      ..removeWhere((id, _) => stored.containsKey(id));
    final result = (saved: stored.length, failed: failed.length);
    state = AsyncData(
      current.copyWith(
        saved: saved,
        pending: pending,
        failed: failed,
        isSaving: false,
        lastResult: () => result,
      ),
    );
    return result;
  }
}
