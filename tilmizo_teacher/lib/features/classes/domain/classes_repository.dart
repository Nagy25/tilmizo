import 'package:core_package/core_package.dart';

import 'class_session.dart';
import 'one_time_session_draft.dart';
import 'schedule_entry.dart';
import 'session_location.dart';

enum SessionsView { upcoming, past, cancelled }

typedef SessionsPage = ({List<ClassSession> sessions, bool hasMore});

/// Sessions and weekly schedules of groups owned by the authenticated
/// teacher. Implementations throw only `AppFailure`, or [ScheduleConflict]
/// for a duplicate active weekly slot.
abstract interface class ClassesRepository {
  /// One page of sessions, optionally limited to [groupId]. Upcoming
  /// sessions are oldest first; past and cancelled sessions newest first.
  Future<SessionsPage> fetchSessions({
    required SessionsView view,
    required DateTime now,
    String? groupId,
    int offset = 0,
    int limit = 30,
  });

  Future<ClassSession?> fetchNextSession({
    required DateTime now,
    String? groupId,
  });

  Future<ClassSession> fetchSession(String sessionId);

  Future<ClassSession> createOneTimeSession(OneTimeSessionDraft draft);

  Future<ClassSession> rescheduleSession(
    String sessionId, {
    required DateTime startsAt,
    required DateTime endsAt,
  });

  Future<ClassSession> changeSessionLocation(
    String sessionId,
    SessionLocation location,
  );

  Future<ClassSession> setSessionStatus(String sessionId, SessionStatus status);

  Future<ClassSession> updateSessionNotes(String sessionId, String? notes);

  /// Active weekly slots of [groupId], ordered by day and start time.
  Future<List<ScheduleEntry>> fetchScheduleEntries(String groupId);

  Future<ScheduleEntry> fetchScheduleEntry(String entryId);

  /// Saves all [slots] atomically: either every slot is created or none.
  Future<void> createScheduleEntries(String groupId, List<WeeklySlot> slots);

  Future<ScheduleEntry> updateScheduleEntry(String entryId, WeeklySlot slot);

  /// Stops future generation for the slot. Existing sessions are kept.
  Future<void> deactivateScheduleEntry(String entryId);
}
