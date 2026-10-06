import 'package:core_package/core_package.dart';

import '../domain/student_class.dart';

abstract final class StudentClassesDto {
  static const sessionColumns =
      'id,group_id,starts_at,ends_at,location_type,physical_location,'
      'meeting_link,status,notes,'
      'group:groups!inner(id,name,subject,grade)';

  static const scheduleColumns =
      'id,group_id,weekday,start_time,end_time,location_type,'
      'physical_location,meeting_link';

  static StudentClassSession sessionFromRow(Map<String, dynamic> row) {
    final group = row['group'] as Map<String, dynamic>;
    return StudentClassSession(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      groupName: group['name'] as String,
      subject: group['subject'] as String?,
      grade: group['grade'] as String?,
      startsAt: DateTime.parse(row['starts_at'] as String).toUtc(),
      endsAt: DateTime.parse(row['ends_at'] as String).toUtc(),
      locationType: SessionLocationType.fromBackend(
        row['location_type'] as String,
      ),
      physicalLocation: row['physical_location'] as String?,
      meetingLink: row['meeting_link'] as String?,
      status: SessionStatus.fromBackend(row['status'] as String),
      notes: row['notes'] as String?,
      attendance: AttendanceStatus.notMarked,
    );
  }

  static StudentScheduleEntry scheduleFromRow(Map<String, dynamic> row) =>
      StudentScheduleEntry(
        id: row['id'] as String,
        groupId: row['group_id'] as String,
        weekday: (row['weekday'] as num).toInt(),
        start: ClockTime.fromBackend(row['start_time'] as String),
        end: ClockTime.fromBackend(row['end_time'] as String),
        locationType: SessionLocationType.fromBackend(
          row['location_type'] as String,
        ),
        physicalLocation: row['physical_location'] as String?,
        meetingLink: row['meeting_link'] as String?,
      );
}
