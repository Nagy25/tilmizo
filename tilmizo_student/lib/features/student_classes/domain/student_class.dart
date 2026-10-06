import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

enum StudentSessionsView { upcoming, past, cancelled }

@immutable
final class StudentClassSession {
  const StudentClassSession({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.startsAt,
    required this.endsAt,
    required this.locationType,
    required this.status,
    required this.attendance,
    this.subject,
    this.grade,
    this.physicalLocation,
    this.meetingLink,
    this.notes,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String? subject;
  final String? grade;
  final DateTime startsAt;
  final DateTime endsAt;
  final SessionLocationType locationType;
  final String? physicalLocation;
  final String? meetingLink;
  final SessionStatus status;
  final String? notes;
  final AttendanceStatus attendance;

  StudentClassSession withAttendance(AttendanceStatus value) =>
      StudentClassSession(
        id: id,
        groupId: groupId,
        groupName: groupName,
        subject: subject,
        grade: grade,
        startsAt: startsAt,
        endsAt: endsAt,
        locationType: locationType,
        physicalLocation: physicalLocation,
        meetingLink: meetingLink,
        status: status,
        notes: notes,
        attendance: value,
      );
}

@immutable
final class StudentScheduleEntry {
  const StudentScheduleEntry({
    required this.id,
    required this.groupId,
    required this.weekday,
    required this.start,
    required this.end,
    required this.locationType,
    this.physicalLocation,
    this.meetingLink,
  });

  final String id;
  final String groupId;
  final int weekday;
  final ClockTime start;
  final ClockTime end;
  final SessionLocationType locationType;
  final String? physicalLocation;
  final String? meetingLink;
}

@immutable
final class StudentSessionsPage {
  const StudentSessionsPage({
    required this.sessions,
    required this.hasMore,
    this.total,
  });

  final List<StudentClassSession> sessions;
  final bool hasMore;
  final int? total;
}
