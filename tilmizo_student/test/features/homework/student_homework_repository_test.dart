import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_student/features/homework/data/student_homework_repository_impl.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> _homework({String id = 'h1'}) => {
  'id': id,
  'group_id': 'g1',
  'session_id': 's1',
  'teacher_id': 't1',
  'instructions': null,
  'submission_type': 'link',
  'due_date': null,
  'created_at': '2026-10-05T10:00:00Z',
  'attachments': [
    {'homework_id': id, 'group_id': 'g1', 'resource_id': 'r1'},
    {'homework_id': id, 'group_id': 'g1', 'resource_id': 'link'},
  ],
};

Map<String, dynamic> _resource(String id, {String type = 'pdf'}) => {
  'id': id,
  'group_id': 'g1',
  'teacher_id': 't1',
  'session_id': null,
  'title': id,
  'description': null,
  'type': type,
  'storage_path': type == 'pdf' ? 't1/g1/$id.pdf' : null,
  'file_name': type == 'pdf' ? '$id.pdf' : null,
  'file_size': type == 'pdf' ? 10 : null,
  'mime_type': type == 'pdf' ? 'application/pdf' : null,
  'external_url': type == 'pdf' ? null : 'https://example.com',
  'created_at': '2026-10-05T10:00:00Z',
  'updated_at': '2026-10-05T10:00:00Z',
};

Map<String, dynamic> _submission({String student = testUserId}) => {
  'homework_id': 'h1',
  'student_id': student,
  'url': 'https://drive.example.com/mine',
  'created_at': '2026-10-06T08:00:00Z',
  'updated_at': '2026-10-06T08:00:00Z',
};

final class _FakeDataSource implements StudentHomeworkRemoteDataSource {
  List<Map<String, dynamic>> homework = [];
  List<Map<String, dynamic>> resources = [];
  Map<String, dynamic>? submission;
  Object? submitResult;
  Object? error;
  final submits = <(String, String)>[];
  ({String homeworkId, String studentId})? submissionQuery;

  @override
  Future<List<Map<String, dynamic>>> fetchHomework({
    String? groupId,
    String? sessionId,
    String? homeworkId,
  }) async {
    if (error case final error?) throw error;
    return homework;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchResources(List<String> ids) async =>
      resources;

  @override
  Future<Map<String, dynamic>?> fetchSubmission({
    required String homeworkId,
    required String studentId,
  }) async {
    submissionQuery = (homeworkId: homeworkId, studentId: studentId);
    return submission;
  }

  @override
  Future<Object?> submitLink(String homeworkId, String url) async {
    submits.add((homeworkId, url));
    if (error case final error?) throw error;
    return submitResult;
  }
}

Matcher _failure(AppFailureType type) =>
    throwsA(isA<AppFailure>().having((f) => f.type, 'type', type));

void main() {
  late _FakeDataSource source;
  late StudentHomeworkRepositoryImpl repository;

  setUp(() {
    source = _FakeDataSource();
    repository = StudentHomeworkRepositoryImpl(
      source,
      FakePhoneAuthService(signedIn: true),
    );
  });

  test('parses homework rows', () async {
    source.homework = [_homework()];
    final list = await repository.fetchGroupHomework('g1');
    expect(list.single.resourceIds, ['r1', 'link']);
    expect(list.single.instructions, isNull);
    expect(await repository.fetchHomework('h1'), isNotNull);
  });

  test('offers only uploaded attachments, in order', () async {
    source.resources = [
      _resource('link', type: 'external_link'),
      _resource('r1'),
    ];
    final files = await repository.fetchResources(['r1', 'link', 'gone']);
    expect(files.map((r) => r.id), ['r1']);
  });

  test("reads only the caller's own link", () async {
    source.submission = _submission();
    final mine = await repository.fetchMySubmission('h1');
    expect(mine?.url, 'https://drive.example.com/mine');
    expect(source.submissionQuery, (homeworkId: 'h1', studentId: testUserId));

    source.submission = _submission(student: 'someone-else');
    expect(await repository.fetchMySubmission('h1'), isNull);
  });

  test('submits a trimmed HTTPS link and validates first', () async {
    source.submitResult = _submission();
    final saved = await repository.submitLink(
      'h1',
      '  https://drive.example.com/mine ',
    );
    expect(saved.url, 'https://drive.example.com/mine');
    expect(source.submits.single, ('h1', 'https://drive.example.com/mine'));

    for (final bad in ['http://x.com', 'drive.example.com', 'https://a b']) {
      await expectLater(
        repository.submitLink('h1', bad),
        _failure(AppFailureType.invalidInput),
      );
    }
    expect(source.submits, hasLength(1));
  });

  test('maps the cutoff/access rejection and invalid links', () async {
    source.error = const PostgrestException(
      message: 'Link submission is not allowed',
      code: '42501',
    );
    await expectLater(
      repository.submitLink('h1', 'https://a.b'),
      _failure(AppFailureType.notEligible),
    );
    source.error = const PostgrestException(
      message: 'A valid HTTPS link is required',
      code: '22023',
    );
    await expectLater(
      repository.submitLink('h1', 'https://a.b'),
      _failure(AppFailureType.invalidInput),
    );
  });
}
