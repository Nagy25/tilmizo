import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_teacher/features/homework/data/homework_remote_data_source.dart';
import 'package:tilmizo_teacher/features/homework/data/homework_repository_impl.dart';
import 'package:tilmizo_teacher/features/homework/domain/homework_repository.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> homeworkRow({String id = 'h1'}) => {
  'id': id,
  'group_id': 'g1',
  'session_id': 's1',
  'teacher_id': 't1',
  'instructions': 'حل التمارين',
  'submission_type': 'link',
  'due_date': '2026-10-10',
  'created_at': '2026-10-05T10:00:00Z',
  'session': {'starts_at': '2026-10-05T14:00:00Z', 'status': 'scheduled'},
  'attachments': [
    {'homework_id': id, 'group_id': 'g1', 'resource_id': 'r1'},
  ],
};

Map<String, dynamic> resourceRow(
  String id, {
  String group = 'g1',
  String type = 'pdf',
  String? session,
}) => {
  'id': id,
  'group_id': group,
  'teacher_id': 't1',
  'session_id': session,
  'title': 'ملف $id',
  'description': null,
  'type': type,
  'storage_path': type == 'external_link' ? null : 't1/$group/$id.pdf',
  'file_name': type == 'external_link' ? null : '$id.pdf',
  'file_size': type == 'external_link' ? null : 1024,
  'mime_type': type == 'external_link' ? null : 'application/pdf',
  'external_url': type == 'external_link' ? 'https://example.com' : null,
  'created_at': '2026-10-05T10:00:00Z',
  'updated_at': '2026-10-05T10:00:00Z',
};

final class _FakeDataSource implements HomeworkRemoteDataSource {
  List<Map<String, dynamic>> homework = [];
  List<Map<String, dynamic>> resources = [];
  List<Map<String, dynamic>> submissions = [];
  Object? rpcResult;
  Object? error;
  final queries = <String>[];
  final rpcs = <(String, Map<String, dynamic>)>[];

  Future<T> _run<T>(String query, T value) async {
    queries.add(query);
    if (error case final error?) throw error;
    return value;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchHomework({
    String? groupId,
    String? sessionId,
    String? homeworkId,
  }) => _run('homework:$groupId:$sessionId:$homeworkId', homework);

  @override
  Future<List<Map<String, dynamic>>> fetchResources(List<String> ids) =>
      _run('resources:${ids.join(',')}', resources);

  @override
  Future<List<Map<String, dynamic>>> fetchAttachableResources({
    required String groupId,
    required String sessionId,
  }) => _run('attachable:$groupId:$sessionId', resources);

  @override
  Future<List<Map<String, dynamic>>> fetchSubmissions(String homeworkId) =>
      _run('submissions:$homeworkId', submissions);

  @override
  Future<Object?> rpc(String function, Map<String, dynamic> params) {
    rpcs.add((function, params));
    return _run('rpc:$function', rpcResult);
  }
}

Matcher _homeworkFailure(HomeworkFailureReason reason) =>
    throwsA(isA<HomeworkFailure>().having((f) => f.reason, 'reason', reason));

void main() {
  late _FakeDataSource source;
  late HomeworkRepositoryImpl repository;

  setUp(() {
    source = _FakeDataSource();
    repository = HomeworkRepositoryImpl(
      source,
      FakePhoneAuthService(signedIn: true),
    );
  });

  test('lists group and session homework with embedded details', () async {
    source.homework = [homeworkRow()];
    final list = await repository.fetchGroupHomework('g1');
    expect(list.single.resourceIds, ['r1']);
    expect(list.single.session?.startsAt, DateTime.utc(2026, 10, 5, 14));
    await repository.fetchSessionHomework('s1');
    expect(await repository.fetchHomework('h1'), isNotNull);
    source.homework = [];
    expect(await repository.fetchHomework('missing'), isNull);
    expect(source.queries.take(2), [
      'homework:g1:null:null',
      'homework:null:s1:null',
    ]);
  });

  group('create_homework', () {
    setUp(() => source.rpcResult = homeworkRow());

    test('text only sends trimmed instructions and no files', () async {
      await repository.createHomework(
        const HomeworkDraft(
          sessionId: 's1',
          instructions: '  حل التمارين \n',
          submissionType: HomeworkSubmissionType.manual,
        ),
      );
      expect(source.rpcs.single.$1, 'create_homework');
      expect(source.rpcs.single.$2, {
        'p_session_id': 's1',
        'p_instructions': 'حل التمارين',
        'p_submission_type': 'manual',
        'p_due_date': null,
        'p_resource_ids': <String>[],
      });
    });

    test('file only sends null instructions and unique resource ids', () async {
      await repository.createHomework(
        const HomeworkDraft(
          sessionId: 's1',
          instructions: '   ',
          submissionType: HomeworkSubmissionType.none,
          resourceIds: ['r1', 'r2', 'r1'],
        ),
      );
      expect(source.rpcs.single.$2['p_instructions'], isNull);
      expect(source.rpcs.single.$2['p_resource_ids'], ['r1', 'r2']);
    });

    test('both, with the due date as a plain calendar date', () async {
      final homework = await repository.createHomework(
        HomeworkDraft(
          sessionId: 's1',
          instructions: 'حل التمارين',
          submissionType: HomeworkSubmissionType.link,
          dueDate: DateTime.utc(2026, 10, 10),
          resourceIds: const ['r1'],
        ),
      );
      expect(source.rpcs.single.$2['p_due_date'], '2026-10-10');
      expect(source.rpcs.single.$2['p_submission_type'], 'link');
      expect(homework.dueDate, DateTime.utc(2026, 10, 10));
    });

    test('blank content or over-long instructions never reach the RPC', () {
      expect(
        repository.createHomework(
          const HomeworkDraft(
            sessionId: 's1',
            instructions: ' ',
            submissionType: HomeworkSubmissionType.manual,
          ),
        ),
        _homeworkFailure(HomeworkFailureReason.invalidContent),
      );
      expect(
        repository.createHomework(
          HomeworkDraft(
            sessionId: 's1',
            instructions: 'ت' * 10001,
            submissionType: HomeworkSubmissionType.manual,
          ),
        ),
        _homeworkFailure(HomeworkFailureReason.invalidContent),
      );
      expect(source.rpcs, isEmpty);
    });
  });

  test(
    'only uploads of the group, general or for this session, attach',
    () async {
      source.resources = [
        resourceRow('general'),
        resourceRow('same-session', session: 's1'),
        resourceRow('other-session', session: 's2'),
        resourceRow('link', type: 'external_link'),
        resourceRow('other-group', group: 'g2'),
      ];
      final resources = await repository.fetchAttachableResources(
        groupId: 'g1',
        sessionId: 's1',
      );
      expect(resources.map((r) => r.id), ['general', 'same-session']);
      expect(source.queries.single, 'attachable:g1:s1');
    },
  );

  test('attachment details keep attachment order and skip missing', () async {
    source.resources = [resourceRow('r2'), resourceRow('r1')];
    final resources = await repository.fetchResources(['r1', 'gone', 'r2']);
    expect(resources.map((r) => r.id), ['r1', 'r2']);
    expect(await repository.fetchResources(const []), isEmpty);
    expect(source.queries, ['resources:r1,gone,r2']);
  });

  test('submissions carry the student name when readable', () async {
    Map<String, dynamic> row(String student, Object? profile) => {
      'homework_id': 'h1',
      'student_id': student,
      'url': 'https://drive.example.com/$student',
      'created_at': '2026-10-06T08:00:00Z',
      'updated_at': '2026-10-06T09:00:00Z',
      'student': profile,
    };
    source.submissions = [
      row('st1', {'full_name': ' سارة أحمد '}),
      row('st2', null),
    ];
    final submissions = await repository.fetchSubmissions('h1');
    expect(submissions.first.studentName, 'سارة أحمد');
    expect(submissions.first.submission.wasReplaced, isTrue);
    expect(submissions.last.studentName, isNull);
    expect(
      SupabaseHomeworkDataSource.submissionColumns,
      contains('profiles!homework_link_submissions_student_id_fkey'),
    );
  });

  test('delete calls only delete_homework, never a Resource delete', () async {
    await repository.deleteHomework('h1');
    expect(source.rpcs.single.$1, 'delete_homework');
    expect(source.rpcs.single.$2, {'p_homework_id': 'h1'});
    expect(source.queries, ['rpc:delete_homework']);
  });

  test('maps RPC rejections to safe reasons', () async {
    const draft = HomeworkDraft(
      sessionId: 's1',
      instructions: 'نص',
      submissionType: HomeworkSubmissionType.manual,
    );
    final cases = {
      const PostgrestException(message: 'Group is not writable', code: '42501'):
          HomeworkFailureReason.groupNotWritable,
      const PostgrestException(
        message: 'An uncancelled session is required',
        code: '22023',
      ): HomeworkFailureReason.sessionCancelled,
      const PostgrestException(
        message: 'Instructions or valid file resources are required',
        code: '22023',
      ): HomeworkFailureReason.invalidContent,
    };
    for (final MapEntry(key: error, value: reason) in cases.entries) {
      source.error = error;
      await expectLater(
        repository.createHomework(draft),
        _homeworkFailure(reason),
      );
    }
    source.error = const PostgrestException(
      message: 'Homework not found',
      code: 'P0002',
    );
    await expectLater(
      repository.deleteHomework('h1'),
      _homeworkFailure(HomeworkFailureReason.notFound),
    );
    source.error = http.ClientException('offline');
    await expectLater(
      repository.fetchGroupHomework('g1'),
      throwsA(
        isA<AppFailure>().having((f) => f.type, 'type', AppFailureType.network),
      ),
    );
  });
}
