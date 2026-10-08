import 'package:core_package/core_package.dart';
import 'package:tilmizo_student/features/homework/domain/student_homework_repository.dart';

import 'fakes.dart';

Homework buildHomework({
  String id = 'hw-1',
  String groupId = 'group-1',
  String sessionId = 'session-1',
  String? instructions = 'حل تمارين صفحة 42',
  HomeworkSubmissionType type = HomeworkSubmissionType.link,
  DateTime? dueDate,
  List<String> resourceIds = const [],
  DateTime? createdAt,
}) => Homework(
  id: id,
  groupId: groupId,
  sessionId: sessionId,
  teacherId: 'teacher-1',
  instructions: instructions,
  submissionType: type,
  dueDate: dueDate,
  createdAt: createdAt ?? DateTime.utc(2026, 10, 5, 10),
  session: HomeworkSession(
    startsAt: DateTime.utc(2026, 10, 5, 14),
    status: SessionStatus.completed,
  ),
  attachments: [
    for (final resourceId in resourceIds)
      HomeworkAttachmentRef(
        homeworkId: id,
        groupId: groupId,
        resourceId: resourceId,
      ),
  ],
);

/// RLS-like fake: rows only for [visibleGroups]; `submit_homework_link`
/// enforces the Cairo cutoff with [serverNow].
final class FakeStudentHomeworkRepository implements StudentHomeworkRepository {
  final homework = <Homework>[];
  final resources = <GroupResource>[];
  final submissions = <String, HomeworkLinkSubmission>{};
  final visibleGroups = <String>{'group-1'};
  final submitCalls = <(String, String)>[];
  DateTime Function() serverNow = () => DateTime.utc(2026, 10, 8, 9);
  AppFailure? failure;
  int fetches = 0;

  Iterable<Homework> get _visible =>
      homework.where((h) => visibleGroups.contains(h.groupId));

  @override
  Future<List<Homework>> fetchGroupHomework(String groupId) async {
    fetches++;
    if (failure case final failure?) throw failure;
    return _sorted(_visible.where((h) => h.groupId == groupId));
  }

  @override
  Future<List<Homework>> fetchSessionHomework(String sessionId) async {
    if (failure case final failure?) throw failure;
    return _sorted(_visible.where((h) => h.sessionId == sessionId));
  }

  @override
  Future<Homework?> fetchHomework(String homeworkId) async {
    if (failure case final failure?) throw failure;
    return _visible.where((h) => h.id == homeworkId).firstOrNull;
  }

  @override
  Future<List<GroupResource>> fetchResources(List<String> resourceIds) async =>
      [
        for (final id in resourceIds)
          ?resources
              .where((r) => r.id == id && visibleGroups.contains(r.groupId))
              .firstOrNull,
      ];

  @override
  Future<HomeworkLinkSubmission?> fetchMySubmission(String homeworkId) async =>
      submissions[homeworkId];

  @override
  Future<HomeworkLinkSubmission> submitLink(
    String homeworkId,
    String url,
  ) async {
    submitCalls.add((homeworkId, url));
    final item = _visible.where((h) => h.id == homeworkId).firstOrNull;
    if (item == null ||
        item.submissionType != HomeworkSubmissionType.link ||
        !item.acceptsSubmissionAt(serverNow())) {
      throw const AppFailure(AppFailureType.notEligible);
    }
    if (!isValidHomeworkLink(url)) {
      throw const AppFailure(AppFailureType.invalidInput);
    }
    final previous = submissions[homeworkId];
    return submissions[homeworkId] = HomeworkLinkSubmission(
      homeworkId: homeworkId,
      studentId: testUserId,
      url: url,
      createdAt: previous?.createdAt ?? serverNow(),
      updatedAt: serverNow(),
    );
  }

  List<Homework> _sorted(Iterable<Homework> rows) =>
      rows.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
