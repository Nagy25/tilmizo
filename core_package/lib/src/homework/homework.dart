import 'package:flutter/foundation.dart';

import '../classes/class_values.dart';
import '../time/cairo_time.dart';
import '../time/calendar_date.dart';

/// The exact `public.homework.submission_type` values.
enum HomeworkSubmissionType {
  /// Students hand the work to the teacher in class; nothing is stored.
  manual('manual'),

  /// Students save one HTTPS link through `submit_homework_link`.
  link('link'),

  /// Content only; nothing is submitted.
  none('none');

  const HomeworkSubmissionType(this.backendValue);

  final String backendValue;

  /// Throws [FormatException] for an unknown value instead of guessing.
  static HomeworkSubmissionType fromBackend(String value) {
    for (final type in values) {
      if (type.backendValue == value) return type;
    }
    throw FormatException('Unknown submission type', value);
  }
}

/// One `homework_resources` row: an uploaded Resource of the same group.
/// File details come from `public.resources`.
@immutable
final class HomeworkAttachmentRef {
  const HomeworkAttachmentRef({
    required this.homeworkId,
    required this.groupId,
    required this.resourceId,
  });

  factory HomeworkAttachmentRef.fromRow(Map<String, dynamic> row) =>
      HomeworkAttachmentRef(
        homeworkId: _required(row, 'homework_id'),
        groupId: _required(row, 'group_id'),
        resourceId: _required(row, 'resource_id'),
      );

  static const columns = 'homework_id, group_id, resource_id';

  final String homeworkId;
  final String groupId;
  final String resourceId;

  @override
  bool operator ==(Object other) =>
      other is HomeworkAttachmentRef &&
      other.homeworkId == homeworkId &&
      other.groupId == groupId &&
      other.resourceId == resourceId;

  @override
  int get hashCode => Object.hash(homeworkId, groupId, resourceId);
}

/// The session a homework belongs to, when embedded with the homework row.
@immutable
final class HomeworkSession {
  const HomeworkSession({required this.startsAt, required this.status});

  factory HomeworkSession.fromRow(Map<String, dynamic> row) => HomeworkSession(
    startsAt: DateTime.parse(_required(row, 'starts_at')).toUtc(),
    status: SessionStatus.fromBackend(_required(row, 'status')),
  );

  final DateTime startsAt;
  final SessionStatus status;

  bool get isCancelled => status == SessionStatus.cancelled;

  @override
  bool operator ==(Object other) =>
      other is HomeworkSession &&
      other.startsAt == startsAt &&
      other.status == status;

  @override
  int get hashCode => Object.hash(startsAt, status);
}

/// One row of `public.homework`, as visible under RLS. There is no title,
/// status or grade, and no edit: a correction is delete and recreate.
@immutable
final class Homework {
  const Homework({
    required this.id,
    required this.groupId,
    required this.sessionId,
    required this.teacherId,
    required this.submissionType,
    required this.createdAt,
    this.instructions,
    this.dueDate,
    this.session,
    this.attachments = const [],
  });

  /// Parses a row selected with [columns] or [listColumns]; the embedded
  /// session and attachments are optional. Throws [FormatException] for a
  /// missing column or an unknown value.
  factory Homework.fromRow(Map<String, dynamic> row) {
    final instructions = row['instructions'];
    return Homework(
      id: _required(row, 'id'),
      groupId: _required(row, 'group_id'),
      sessionId: _required(row, 'session_id'),
      teacherId: _required(row, 'teacher_id'),
      instructions: instructions is String && instructions.trim().isNotEmpty
          ? instructions
          : null,
      submissionType: HomeworkSubmissionType.fromBackend(
        _required(row, 'submission_type'),
      ),
      dueDate: switch (row['due_date']) {
        final String date => parseCalendarDate(date),
        _ => null,
      },
      createdAt: DateTime.parse(_required(row, 'created_at')).toUtc(),
      session: switch (row['session']) {
        final Map<String, dynamic> session => HomeworkSession.fromRow(session),
        _ => null,
      },
      attachments: switch (row['attachments']) {
        final List<dynamic> rows => [
          for (final attachment in rows.cast<Map<String, dynamic>>())
            HomeworkAttachmentRef.fromRow(attachment),
        ],
        _ => const [],
      },
    );
  }

  /// The `homework` columns.
  static const columns =
      'id, group_id, session_id, teacher_id, instructions, submission_type, '
      'due_date, created_at';

  /// [columns] with the session date and attachment references embedded.
  static const listColumns =
      '$columns, '
      'session:class_sessions!homework_session_group_fk(starts_at, status), '
      'attachments:homework_resources(${HomeworkAttachmentRef.columns})';

  /// Backend `char_length` limit of [instructions].
  static const instructionsMaxLength = 10000;

  final String id;
  final String groupId;
  final String sessionId;
  final String teacherId;

  /// Trimmed by the backend; null when the homework is files only.
  final String? instructions;
  final HomeworkSubmissionType submissionType;

  /// The last Cairo calendar day for link submissions (UTC midnight value),
  /// or null when submissions stay open.
  final DateTime? dueDate;
  final DateTime createdAt;
  final HomeworkSession? session;
  final List<HomeworkAttachmentRef> attachments;

  List<String> get resourceIds => [
    for (final attachment in attachments) attachment.resourceId,
  ];

  /// Whether a link may still be saved at [now]: through the end of
  /// [dueDate] in Africa/Cairo, or always without one. The server enforces
  /// the same cutoff and wins if the device clock disagrees.
  bool acceptsSubmissionAt(DateTime now) {
    final due = dueDate;
    return due == null || !CairoTime.dateOf(now).isAfter(due);
  }

  @override
  bool operator ==(Object other) =>
      other is Homework &&
      other.id == id &&
      other.groupId == groupId &&
      other.sessionId == sessionId &&
      other.teacherId == teacherId &&
      other.instructions == instructions &&
      other.submissionType == submissionType &&
      other.dueDate == dueDate &&
      other.createdAt == createdAt &&
      other.session == session &&
      listEquals(other.attachments, attachments);

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    sessionId,
    teacherId,
    instructions,
    submissionType,
    dueDate,
    createdAt,
    session,
    Object.hashAll(attachments),
  );
}

/// A student's saved link for link-type homework. Students read only their
/// own row; the owning teacher reads the group's rows.
@immutable
final class HomeworkLinkSubmission {
  const HomeworkLinkSubmission({
    required this.homeworkId,
    required this.studentId,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeworkLinkSubmission.fromRow(Map<String, dynamic> row) =>
      HomeworkLinkSubmission(
        homeworkId: _required(row, 'homework_id'),
        studentId: _required(row, 'student_id'),
        url: _required(row, 'url'),
        createdAt: DateTime.parse(_required(row, 'created_at')).toUtc(),
        updatedAt: DateTime.parse(_required(row, 'updated_at')).toUtc(),
      );

  static const columns = 'homework_id, student_id, url, created_at, updated_at';

  /// Backend limit of [url].
  static const urlMaxLength = 2048;

  final String homeworkId;
  final String studentId;
  final String url;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether the student replaced the first link.
  bool get wasReplaced => updatedAt.isAfter(createdAt);

  @override
  bool operator ==(Object other) =>
      other is HomeworkLinkSubmission &&
      other.homeworkId == homeworkId &&
      other.studentId == studentId &&
      other.url == url &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(homeworkId, studentId, url, createdAt, updatedAt);
}

/// Whether [url] matches the backend check `^https://[^[:space:]]+$` within
/// [HomeworkLinkSubmission.urlMaxLength] characters.
bool isValidHomeworkLink(String url) =>
    url.runes.length <= HomeworkLinkSubmission.urlMaxLength &&
    RegExp(r'^https://\S+$', caseSensitive: false).hasMatch(url);

String _required(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing homework column', key);
}
