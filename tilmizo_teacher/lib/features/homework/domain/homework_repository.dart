import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// What the teacher fills in before `create_homework`. At least non-blank
/// [instructions] or one uploaded Resource is required.
@immutable
final class HomeworkDraft {
  const HomeworkDraft({
    required this.sessionId,
    required this.submissionType,
    this.instructions = '',
    this.dueDate,
    this.resourceIds = const [],
  });

  final String sessionId;
  final String instructions;
  final HomeworkSubmissionType submissionType;

  /// A Cairo calendar date, sent as `YYYY-MM-DD`.
  final DateTime? dueDate;
  final List<String> resourceIds;

  String? get trimmedInstructions {
    final text = instructions.trim();
    return text.isEmpty ? null : text;
  }

  bool get hasContent => trimmedInstructions != null || resourceIds.isNotEmpty;

  bool get instructionsTooLong =>
      (trimmedInstructions?.runes.length ?? 0) > Homework.instructionsMaxLength;
}

/// A student's saved link with the display name the teacher can read.
@immutable
final class TeacherHomeworkSubmission {
  const TeacherHomeworkSubmission({required this.submission, this.studentName});

  final HomeworkLinkSubmission submission;
  final String? studentName;
}

enum HomeworkFailureReason {
  /// The group is archived, suspended or not owned.
  groupNotWritable,
  sessionCancelled,

  /// Blank content, or an attachment that is no longer a compatible upload.
  invalidContent,
  notFound,
}

/// A homework RPC rejection whose reason helps the teacher.
final class HomeworkFailure implements Exception {
  const HomeworkFailure(this.reason);

  final HomeworkFailureReason reason;

  @override
  String toString() => 'HomeworkFailure(${reason.name})';
}

/// Teacher access to homework. Reads use the Data API under RLS; writes use
/// `create_homework` and `delete_homework` only. There is no edit.
abstract interface class HomeworkRepository {
  /// Newest first, with session dates and attachment references.
  Future<List<Homework>> fetchGroupHomework(String groupId);

  Future<List<Homework>> fetchSessionHomework(String sessionId);

  /// Null when missing or hidden by RLS.
  Future<Homework?> fetchHomework(String homeworkId);

  /// Resource rows for attachment ids; missing ids are simply absent.
  Future<List<GroupResource>> fetchResources(List<String> resourceIds);

  /// Uploaded Resources of [groupId] that are general or assigned to
  /// [sessionId], newest first.
  Future<List<GroupResource>> fetchAttachableResources({
    required String groupId,
    required String sessionId,
  });

  Future<List<TeacherHomeworkSubmission>> fetchSubmissions(String homeworkId);

  Future<Homework> createHomework(HomeworkDraft draft);

  /// Deletes the homework and its link submissions; Resource files stay.
  Future<void> deleteHomework(String homeworkId);
}

/// Whether [resource] may be attached to homework of [sessionId] in
/// [groupId], mirroring the `create_homework` check.
bool isAttachableResource(
  GroupResource resource, {
  required String groupId,
  required String sessionId,
}) =>
    resource.groupId == groupId &&
    resource.type.isUpload &&
    resource.storagePath != null &&
    (resource.sessionId == null || resource.sessionId == sessionId);
