import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:tilmizo_teacher/features/attendance/domain/attendance_repository.dart';
import 'package:tilmizo_teacher/features/attendance/domain/attendance_roster.dart';
import 'package:tilmizo_teacher/features/classes/domain/class_session.dart';
import 'package:tilmizo_teacher/features/classes/domain/classes_repository.dart';
import 'package:tilmizo_teacher/features/classes/domain/one_time_session_draft.dart';
import 'package:tilmizo_teacher/features/classes/domain/schedule_entry.dart';
import 'package:tilmizo_teacher/features/classes/domain/session_location.dart';

/// 17:00–18:30 Cairo time (UTC+3 in October 2026 before DST ends).
ClassSession buildSession({
  String id = 'session-1',
  String groupId = 'group-1',
  String groupName = 'مجموعة التفوق',
  String? subject = 'الرياضيات',
  bool groupActive = true,
  bool groupSuspended = false,
  DateTime? startsAt,
  Duration duration = const Duration(minutes: 90),
  SessionLocation location = const SessionLocation.physical('سنتر الأوائل'),
  SessionStatus status = SessionStatus.scheduled,
  String? scheduleEntryId,
  String? notes,
}) {
  final start = startsAt ?? DateTime.utc(2026, 10, 1, 14);
  return ClassSession(
    id: id,
    group: SessionGroup(
      id: groupId,
      name: groupName,
      subject: subject,
      isActive: groupActive,
      isSuspended: groupSuspended,
    ),
    startsAt: start,
    endsAt: start.add(duration),
    location: location,
    status: status,
    scheduleEntryId: scheduleEntryId,
    notes: notes,
  );
}

AttendanceStudent buildStudent(
  String id, {
  String? name,
  AttendanceStatus saved = AttendanceStatus.notMarked,
}) => AttendanceStudent(
  studentId: id,
  studentName: name ?? 'طالب $id',
  studentPhone: '+2010000000$id',
  savedStatus: saved,
);

final class FakeClassesRepository implements ClassesRepository {
  FakeClassesRepository({
    List<ClassSession>? sessions,
    List<ScheduleEntry>? entries,
  }) : sessions = [...?sessions],
       entries = [...?entries];

  final List<ClassSession> sessions;
  final List<ScheduleEntry> entries;
  AppFailure? fetchFailure;
  Object? mutationFailure;
  Completer<void>? pendingMutation;
  final createdDrafts = <OneTimeSessionDraft>[];
  final createdSlots = <List<WeeklySlot>>[];
  final updates = <({String id, String change})>[];
  int _nextId = 100;

  @override
  Future<SessionsPage> fetchSessions({
    required SessionsView view,
    required DateTime now,
    String? groupId,
    int offset = 0,
    int limit = 30,
  }) async {
    if (fetchFailure case final failure?) throw failure;
    final matching = sessions.where((s) {
      if (groupId != null && s.group.id != groupId) return false;
      return switch (view) {
        SessionsView.upcoming => s.isUpcoming(now),
        SessionsView.cancelled => s.isCancelled,
        SessionsView.past =>
          !s.isCancelled &&
              (s.status == SessionStatus.completed || !s.endsAt.isAfter(now)),
      };
    }).toList();
    matching.sort(
      (a, b) => view == SessionsView.upcoming
          ? a.startsAt.compareTo(b.startsAt)
          : b.startsAt.compareTo(a.startsAt),
    );
    final page = matching.skip(offset).take(limit).toList();
    return (sessions: page, hasMore: page.length == limit);
  }

  @override
  Future<ClassSession?> fetchNextSession({
    required DateTime now,
    String? groupId,
  }) async => (await fetchSessions(
    view: SessionsView.upcoming,
    now: now,
    groupId: groupId,
    limit: 1,
  )).sessions.firstOrNull;

  @override
  Future<ClassSession> fetchSession(String sessionId) async {
    if (fetchFailure case final failure?) throw failure;
    return sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw const AppFailure(AppFailureType.notFound),
    );
  }

  @override
  Future<ClassSession> createOneTimeSession(OneTimeSessionDraft draft) async {
    createdDrafts.add(draft);
    await _beforeMutation();
    final session = buildSession(
      id: 'session-${_nextId++}',
      groupId: draft.groupId,
      startsAt: draft.startsAt,
      duration: draft.endsAt.difference(draft.startsAt),
      location: draft.location,
      notes: draft.notes,
    );
    sessions.add(session);
    return session;
  }

  @override
  Future<ClassSession> rescheduleSession(
    String sessionId, {
    required DateTime startsAt,
    required DateTime endsAt,
  }) => _replace(
    sessionId,
    'reschedule',
    (s) => _copy(s, startsAt: startsAt, endsAt: endsAt),
  );

  @override
  Future<ClassSession> changeSessionLocation(
    String sessionId,
    SessionLocation location,
  ) => _replace(sessionId, 'location', (s) => _copy(s, location: location));

  @override
  Future<ClassSession> setSessionStatus(
    String sessionId,
    SessionStatus status,
  ) =>
      _replace(sessionId, status.backendValue, (s) => _copy(s, status: status));

  @override
  Future<ClassSession> updateSessionNotes(String sessionId, String? notes) =>
      _replace(
        sessionId,
        'notes',
        (s) => _copy(s, notes: () => trimToNull(notes)),
      );

  @override
  Future<List<ScheduleEntry>> fetchScheduleEntries(String groupId) async {
    if (fetchFailure case final failure?) throw failure;
    return entries.where((e) => e.groupId == groupId && e.isActive).toList();
  }

  @override
  Future<ScheduleEntry> fetchScheduleEntry(String entryId) async =>
      entries.firstWhere(
        (e) => e.id == entryId,
        orElse: () => throw const AppFailure(AppFailureType.notFound),
      );

  @override
  Future<void> createScheduleEntries(
    String groupId,
    List<WeeklySlot> slots,
  ) async {
    createdSlots.add(slots);
    await _beforeMutation();
    for (final slot in slots) {
      entries.add(
        ScheduleEntry(
          id: 'entry-${_nextId++}',
          groupId: groupId,
          slot: slot,
          isActive: true,
        ),
      );
    }
  }

  @override
  Future<ScheduleEntry> updateScheduleEntry(
    String entryId,
    WeeklySlot slot,
  ) async {
    await _beforeMutation();
    final index = entries.indexWhere((e) => e.id == entryId);
    final updated = ScheduleEntry(
      id: entryId,
      groupId: entries[index].groupId,
      slot: slot,
      isActive: true,
    );
    entries[index] = updated;
    return updated;
  }

  @override
  Future<void> deactivateScheduleEntry(String entryId) async {
    await _beforeMutation();
    final index = entries.indexWhere((e) => e.id == entryId);
    final entry = entries[index];
    entries[index] = ScheduleEntry(
      id: entry.id,
      groupId: entry.groupId,
      slot: entry.slot,
      isActive: false,
    );
  }

  Future<ClassSession> _replace(
    String id,
    String change,
    ClassSession Function(ClassSession) update,
  ) async {
    updates.add((id: id, change: change));
    await _beforeMutation();
    final index = sessions.indexWhere((s) => s.id == id);
    if (index < 0) throw const AppFailure(AppFailureType.notFound);
    return sessions[index] = update(sessions[index]);
  }

  Future<void> _beforeMutation() async {
    if (pendingMutation case final pending?) await pending.future;
    if (mutationFailure case final failure?) throw failure;
  }

  static ClassSession _copy(
    ClassSession s, {
    DateTime? startsAt,
    DateTime? endsAt,
    SessionLocation? location,
    SessionStatus? status,
    String? Function()? notes,
  }) => ClassSession(
    id: s.id,
    group: s.group,
    scheduleEntryId: s.scheduleEntryId,
    startsAt: startsAt ?? s.startsAt,
    endsAt: endsAt ?? s.endsAt,
    location: location ?? s.location,
    status: status ?? s.status,
    notes: notes == null ? s.notes : notes(),
  );
}

final class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({
    List<AttendanceStudent>? current,
    List<AttendanceStudent>? former,
  }) : current = [...?current],
       former = [...?former];

  final List<AttendanceStudent> current;
  final List<AttendanceStudent> former;
  AppFailure? fetchFailure;

  /// Students whose writes are rejected.
  final failingStudents = <String>{};
  final writes = <({String studentId, AttendanceStatus status})>[];

  @override
  Future<AttendanceRoster> fetchRoster({
    required String groupId,
    required String sessionId,
  }) async {
    if (fetchFailure case final failure?) throw failure;
    return AttendanceRoster(current: [...current], former: [...former]);
  }

  @override
  Future<AttendanceStatus> setAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) async {
    writes.add((studentId: studentId, status: status));
    if (failingStudents.contains(studentId)) {
      throw const AppFailure(AppFailureType.invalidInput);
    }
    return status;
  }
}
