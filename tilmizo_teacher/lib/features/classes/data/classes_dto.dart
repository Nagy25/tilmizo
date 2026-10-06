import 'package:core_package/core_package.dart';

import '../domain/class_session.dart';
import '../domain/one_time_session_draft.dart';
import '../domain/schedule_entry.dart';
import '../domain/session_location.dart';

/// Column mapping for `public.class_sessions` and
/// `public.group_schedule_entries`.
abstract final class ClassesDto {
  static const sessionColumns =
      'id, group_id, schedule_entry_id, starts_at, ends_at, location_type, '
      'physical_location, meeting_link, status, notes, '
      'group:groups!inner(id, name, subject, is_active, teacher_id)';

  static const entryColumns =
      'id, group_id, weekday, start_time, end_time, location_type, '
      'physical_location, meeting_link, is_active, '
      'owner:groups!inner(teacher_id)';

  static ClassSession sessionFromRow(Map<String, dynamic> row) {
    final group = row['group'] as Map<String, dynamic>;
    return ClassSession(
      id: row['id'] as String,
      group: SessionGroup(
        id: group['id'] as String,
        name: group['name'] as String,
        subject: group['subject'] as String?,
        isActive: group['is_active'] as bool,
      ),
      scheduleEntryId: row['schedule_entry_id'] as String?,
      startsAt: DateTime.parse(row['starts_at'] as String).toUtc(),
      endsAt: DateTime.parse(row['ends_at'] as String).toUtc(),
      location: SessionLocation.fromColumns(row),
      status: SessionStatus.fromBackend(row['status'] as String),
      notes: row['notes'] as String?,
    );
  }

  static ScheduleEntry entryFromRow(Map<String, dynamic> row) => ScheduleEntry(
    id: row['id'] as String,
    groupId: row['group_id'] as String,
    isActive: row['is_active'] as bool,
    slot: WeeklySlot(
      weekday: (row['weekday'] as num).toInt(),
      start: ClockTime.fromBackend(row['start_time'] as String),
      end: ClockTime.fromBackend(row['end_time'] as String),
      location: SessionLocation.fromColumns(row),
    ),
  );

  /// Teacher-writable schedule columns; generation starts once saved.
  static Map<String, dynamic> slotPayload(WeeklySlot slot) => {
    'weekday': slot.weekday,
    'start_time': slot.start.backendValue,
    'end_time': slot.end.backendValue,
    ...slot.location.toColumns(),
  };

  static Map<String, dynamic> createSessionParams(OneTimeSessionDraft draft) =>
      {
        'p_group_id': draft.groupId,
        'p_starts_at': draft.startsAt.toUtc().toIso8601String(),
        'p_ends_at': draft.endsAt.toUtc().toIso8601String(),
        'p_location_type': draft.location.type.backendValue,
        'p_physical_location': draft.location.physicalLocation,
        'p_meeting_link': draft.location.meetingLink,
        'p_notes': draft.notes,
      };
}
