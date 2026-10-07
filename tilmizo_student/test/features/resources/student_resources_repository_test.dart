import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_student/features/resources/data/student_resources_repository_impl.dart';

final class _FakeDataSource implements StudentResourcesRemoteDataSource {
  List<Map<String, dynamic>> rows = [];
  Object? error;
  ({String groupId, int offset, int limit})? lastPage;

  @override
  Future<List<Map<String, dynamic>>> fetchResources(
    String groupId, {
    required int offset,
    required int limit,
  }) async {
    if (error case final error?) throw error;
    lastPage = (groupId: groupId, offset: offset, limit: limit);
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTypes(String groupId) async => rows;

  @override
  Future<List<Map<String, dynamic>>> fetchSessions(String groupId) async => [
    {'id': 's1', 'starts_at': '2026-10-05T14:30:00Z', 'status': 'cancelled'},
  ];
}

Map<String, dynamic> _row({String type = 'pdf'}) => {
  'id': 'r1',
  'group_id': 'g1',
  'teacher_id': 't1',
  'session_id': 's1',
  'title': 'Notes',
  'description': 'Read',
  'type': type,
  'storage_path': 't1/g1/r1.pdf',
  'file_name': 'notes.pdf',
  'file_size': 10,
  'mime_type': 'application/pdf',
  'external_url': null,
  'created_at': '2026-10-05T10:00:00Z',
  'updated_at': '2026-10-05T10:00:00Z',
};

void main() {
  late _FakeDataSource source;
  late StudentResourcesRepositoryImpl repository;

  setUp(() {
    source = _FakeDataSource();
    repository = StudentResourcesRepositoryImpl(source);
  });

  test('parses rows and pages by offset', () async {
    source.rows = [_row()];
    final page = await repository.fetchResources('g1', offset: 30, limit: 1);

    expect(source.lastPage, (groupId: 'g1', offset: 30, limit: 1));
    expect(page.resources.single.sessionId, 's1');
    expect(page.resources.single.storagePath, 't1/g1/r1.pdf');
    expect(page.hasMore, isTrue);
  });

  test('RLS hiding every row yields an empty list', () async {
    final page = await repository.fetchResources('g1');
    expect(page.resources, isEmpty);
    expect(await repository.fetchTypeCounts('g1'), isEmpty);
  });

  test('maps denied and offline reads to app failures', () async {
    source.error = const PostgrestException(
      message: 'JWT expired',
      code: 'PGRST301',
    );
    await expectLater(
      repository.fetchResources('g1'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.type,
          'type',
          AppFailureType.sessionExpired,
        ),
      ),
    );
  });

  test('an unknown resource type is a failure, not a guess', () async {
    source.rows = [_row(type: 'audio')];
    await expectLater(
      repository.fetchResources('g1'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('parses session labels', () async {
    final sessions = await repository.fetchSessions('g1');
    expect(sessions.single.status, SessionStatus.cancelled);
  });
}
