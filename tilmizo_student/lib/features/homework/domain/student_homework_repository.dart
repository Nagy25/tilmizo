import 'package:core_package/core_package.dart';

/// Read-only homework of approved groups plus the student's own link. RLS
/// returns rows only while this signed-in session is the approved one.
abstract interface class StudentHomeworkRepository {
  /// Newest first, with session dates and attachment references.
  Future<List<Homework>> fetchGroupHomework(String groupId);

  Future<List<Homework>> fetchSessionHomework(String sessionId);

  /// Null when missing or hidden by RLS.
  Future<Homework?> fetchHomework(String homeworkId);

  /// Resource rows for attachment ids, in that order; hidden ids are absent.
  Future<List<GroupResource>> fetchResources(List<String> resourceIds);

  /// The caller's saved link, or null.
  Future<HomeworkLinkSubmission?> fetchMySubmission(String homeworkId);

  /// Creates or replaces the caller's HTTPS link. Rejected with
  /// [AppFailureType.invalidInput] for a bad link and
  /// [AppFailureType.notEligible] when submission is closed or access lost.
  Future<HomeworkLinkSubmission> submitLink(String homeworkId, String url);
}
