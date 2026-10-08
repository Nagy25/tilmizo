import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:tilmizo_teacher/features/homework/domain/homework_repository.dart';

import 'fakes.dart';

Homework buildHomework({
  String id = 'hw-1',
  String groupId = 'group-1',
  String sessionId = 'session-1',
  String? instructions = 'حل تمارين صفحة 42',
  HomeworkSubmissionType type = HomeworkSubmissionType.link,
  DateTime? dueDate,
  List<String> resourceIds = const [],
  DateTime? sessionStartsAt,
  SessionStatus sessionStatus = SessionStatus.scheduled,
  DateTime? createdAt,
}) => Homework(
  id: id,
  groupId: groupId,
  sessionId: sessionId,
  teacherId: testUserId,
  instructions: instructions,
  submissionType: type,
  dueDate: dueDate,
  createdAt: createdAt ?? testTime,
  session: HomeworkSession(
    startsAt: sessionStartsAt ?? DateTime.utc(2026, 10, 1, 14),
    status: sessionStatus,
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

/// In-memory [HomeworkRepository] following the RPC contract: content is
/// required, only compatible uploads attach, and delete never touches
/// Resources.
final class FakeHomeworkRepository implements HomeworkRepository {
  FakeHomeworkRepository({
    List<Homework>? homework,
    List<GroupResource>? resources,
  }) : homework = [...?homework],
       resources = [...?resources];

  final List<Homework> homework;

  /// The group's Resources, as RLS returns them.
  final List<GroupResource> resources;
  final submissions = <String, List<TeacherHomeworkSubmission>>{};
  final drafts = <HomeworkDraft>[];
  final calls = <String>[];
  AppFailure? fetchFailure;
  Exception? mutationFailure;
  Completer<void>? pendingMutation;
  int _nextId = 100;

  @override
  Future<List<Homework>> fetchGroupHomework(String groupId) async {
    if (fetchFailure case final failure?) throw failure;
    return _sorted(homework.where((h) => h.groupId == groupId));
  }

  @override
  Future<List<Homework>> fetchSessionHomework(String sessionId) async {
    if (fetchFailure case final failure?) throw failure;
    return _sorted(homework.where((h) => h.sessionId == sessionId));
  }

  @override
  Future<Homework?> fetchHomework(String homeworkId) async {
    if (fetchFailure case final failure?) throw failure;
    return homework.where((h) => h.id == homeworkId).firstOrNull;
  }

  @override
  Future<List<GroupResource>> fetchResources(List<String> resourceIds) async =>
      [
        for (final id in resourceIds)
          ?resources.where((r) => r.id == id).firstOrNull,
      ];

  @override
  Future<List<GroupResource>> fetchAttachableResources({
    required String groupId,
    required String sessionId,
  }) async => [
    for (final resource in resources)
      if (isAttachableResource(
        resource,
        groupId: groupId,
        sessionId: sessionId,
      ))
        resource,
  ];

  @override
  Future<List<TeacherHomeworkSubmission>> fetchSubmissions(
    String homeworkId,
  ) async => submissions[homeworkId] ?? const [];

  @override
  Future<Homework> createHomework(HomeworkDraft draft) async {
    calls.add('create:${draft.sessionId}');
    drafts.add(draft);
    await pendingMutation?.future;
    if (mutationFailure case final failure?) throw failure;
    if (!draft.hasContent) {
      throw const HomeworkFailure(HomeworkFailureReason.invalidContent);
    }
    final created = buildHomework(
      id: 'hw-${_nextId++}',
      sessionId: draft.sessionId,
      instructions: draft.trimmedInstructions,
      type: draft.submissionType,
      dueDate: draft.dueDate,
      resourceIds: draft.resourceIds,
      createdAt: testTime.add(Duration(minutes: _nextId)),
    );
    homework.add(created);
    return created;
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    calls.add('delete:$homeworkId');
    await pendingMutation?.future;
    if (mutationFailure case final failure?) throw failure;
    homework.removeWhere((h) => h.id == homeworkId);
    submissions.remove(homeworkId);
  }

  List<Homework> _sorted(Iterable<Homework> rows) =>
      rows.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
