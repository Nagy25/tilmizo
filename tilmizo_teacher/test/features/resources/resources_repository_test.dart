import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_teacher/features/resources/data/resources_remote_data_source.dart';
import 'package:tilmizo_teacher/features/resources/data/resources_repository_impl.dart';
import 'package:tilmizo_teacher/features/resources/domain/resource_failure.dart';
import 'package:tilmizo_teacher/features/resources/domain/resource_models.dart';

import '../../helpers/fake_resources.dart';

Map<String, dynamic> _row({
  String id = 'r1',
  String type = 'pdf',
  String? url,
}) => {
  'id': id,
  'group_id': 'g1',
  'teacher_id': 't1',
  'session_id': null,
  'title': 'Notes',
  'description': null,
  'type': type,
  'storage_path': url == null ? 't1/g1/$id.pdf' : null,
  'file_name': url == null ? 'notes.pdf' : null,
  'file_size': url == null ? 10 : null,
  'mime_type': url == null ? 'application/pdf' : null,
  'external_url': url,
  'created_at': '2026-10-05T10:00:00Z',
  'updated_at': '2026-10-05T10:00:00Z',
};

final class _FakeDataSource implements ResourcesRemoteDataSource {
  List<Map<String, dynamic>> rows = [];
  Map<String, dynamic>? single;
  final rpcCalls = <(String, Map<String, dynamic>)>[];
  final functionCalls = <(String, Map<String, dynamic>)>[];
  ({int status, Map<String, dynamic> body}) functionResponse = (
    status: 200,
    body: {},
  );
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
  Future<Map<String, dynamic>?> fetchResource(String resourceId) async =>
      single;

  @override
  Future<List<Map<String, dynamic>>> fetchTypes(String groupId) async => rows;

  @override
  Future<List<Map<String, dynamic>>> fetchSessions(String groupId) async => [
    {'id': 's1', 'starts_at': '2026-10-05T14:30:00Z', 'status': 'scheduled'},
  ];

  @override
  Future<Map<String, dynamic>> callRpc(
    String function,
    Map<String, dynamic> params,
  ) async {
    rpcCalls.add((function, params));
    if (error case final error?) throw error;
    return single ?? _row();
  }

  @override
  Future<({int status, Map<String, dynamic> body})> invokeFunction(
    String function,
    Map<String, dynamic> body,
  ) async {
    functionCalls.add((function, body));
    if (error case final error?) throw error;
    return functionResponse;
  }
}

const _details = ResourceDetails(
  title: 'Notes',
  description: 'Read',
  sessionId: 's1',
);

void main() {
  late _FakeDataSource source;
  late ResourcesRepositoryImpl repository;

  setUp(() {
    source = _FakeDataSource();
    repository = ResourcesRepositoryImpl(source);
  });

  test('pages resources and reports whether more exist', () async {
    source.rows = [_row(id: 'a'), _row(id: 'b')];
    final page = await repository.fetchResources('g1', offset: 30, limit: 2);

    expect(source.lastPage, (groupId: 'g1', offset: 30, limit: 2));
    expect(page.resources.map((r) => r.id), ['a', 'b']);
    expect(page.hasMore, isTrue);
  });

  test('an RLS-filtered result is an empty page, not an error', () async {
    final page = await repository.fetchResources('hidden-group');
    expect(page.resources, isEmpty);
    expect(page.hasMore, isFalse);
  });

  test('counts every type for the group', () async {
    source.rows = [
      {'type': 'pdf'},
      {'type': 'pdf'},
      {'type': 'video_link'},
    ];
    expect(await repository.fetchTypeCounts('g1'), {
      ResourceType.pdf: 2,
      ResourceType.videoLink: 1,
    });
  });

  test('parses session options', () async {
    final sessions = await repository.fetchSessions('g1');
    expect(sessions.single.id, 's1');
    expect(sessions.single.status, SessionStatus.scheduled);
  });

  test('creates links through create_external_resource', () async {
    source.single = _row(type: 'external_link', url: 'https://a.test');
    final resource = await repository.createLink(
      groupId: 'g1',
      type: ResourceType.externalLink,
      url: 'https://a.test',
      details: _details,
    );

    expect(source.rpcCalls.single.$1, 'create_external_resource');
    expect(source.rpcCalls.single.$2, {
      'p_group_id': 'g1',
      'p_title': 'Notes',
      'p_type': 'external_link',
      'p_external_url': 'https://a.test',
      'p_description': 'Read',
      'p_session_id': 's1',
    });
    expect(resource.type, ResourceType.externalLink);
  });

  test('updates every editable field through update_resource_metadata', () {
    repository.updateMetadata(
      resourceId: 'r1',
      details: _details,
      url: 'https://kept.test',
    );
    expect(source.rpcCalls.single.$1, 'update_resource_metadata');
    expect(source.rpcCalls.single.$2, {
      'p_resource_id': 'r1',
      'p_title': 'Notes',
      'p_description': 'Read',
      'p_session_id': 's1',
      'p_external_url': 'https://kept.test',
    });
  });

  test('reserves, finalizes and cancels through resource-upload', () async {
    source.functionResponse = (
      status: 201,
      body: {
        'reservation_id': 'r9',
        'bucket': 'group-resources',
        'storage_path': 't1/g1/r9.pdf',
        'signed_upload_token': 'tok',
        'signed_upload_url': 'https://x',
        'use_resumable_upload': true,
      },
    );
    final reservation = await repository.reserveUpload(
      groupId: 'g1',
      type: ResourceType.pdf,
      file: pickedPdf(size: 7 * mib),
      details: _details,
    );
    expect(source.functionCalls.single.$1, 'resource-upload');
    expect(source.functionCalls.single.$2, {
      'action': 'reserve',
      'type': 'pdf',
      'group_id': 'g1',
      'title': 'Notes',
      'description': 'Read',
      'session_id': 's1',
      'file_name': 'notes.pdf',
      'file_size': 7 * mib,
      'mime_type': 'application/pdf',
    });
    expect(reservation.storagePath, 't1/g1/r9.pdf');
    expect(reservation.signedUploadToken, 'tok');
    expect(reservation.useResumableUpload, isTrue);

    source.functionResponse = (status: 200, body: {'resource': _row(id: 'r9')});
    expect((await repository.finalizeUpload('r9')).id, 'r9');
    expect(source.functionCalls.last.$2, {
      'action': 'finalize',
      'reservation_id': 'r9',
    });

    await repository.cancelUpload('r9');
    expect(source.functionCalls.last.$2, {
      'action': 'cancel',
      'reservation_id': 'r9',
    });
  });

  test('cancelling an already finalized upload is not an error', () async {
    source.error = const FunctionException(
      status: 422,
      details: {'error': 'finalized_upload_cannot_be_cancelled'},
    );
    await repository.cancelUpload('r9');
  });

  test('delete treats 200 and 202 as deleted', () async {
    source.functionResponse = (
      status: 200,
      body: {'deleted': true, 'cleanup_pending': false},
    );
    expect((await repository.deleteResource('r1')).cleanupPending, isFalse);
    expect(source.functionCalls.single.$1, 'resource-delete');
    expect(source.functionCalls.single.$2, {'resource_id': 'r1'});

    source.functionResponse = (
      status: 202,
      body: {'deleted': true, 'cleanup_pending': true},
    );
    expect((await repository.deleteResource('r1')).cleanupPending, isTrue);
  });

  group('maps backend rejections', () {
    Future<Object?> failureOf(Object error) async {
      source.error = error;
      try {
        await repository.reserveUpload(
          groupId: 'g1',
          type: ResourceType.pdf,
          file: pickedPdf(),
          details: _details,
        );
      } catch (failure) {
        return failure;
      }
      return null;
    }

    FunctionException rejected(String message) =>
        FunctionException(status: 422, details: {'error': message});

    test('quota, size, content and archived-group messages', () async {
      expect(
        await failureOf(
          rejected('The teacher storage quota would be exceeded'),
        ),
        isA<ResourceFailure>().having(
          (f) => f.reason,
          'reason',
          ResourceFailureReason.quotaExceeded,
        ),
      );
      expect(
        await failureOf(rejected('The file exceeds the configured type limit')),
        isA<ResourceFailure>().having(
          (f) => f.reason,
          'reason',
          ResourceFailureReason.fileTooLarge,
        ),
      );
      expect(
        await failureOf(rejected('invalid_pdf_content')),
        isA<ResourceFailure>().having(
          (f) => f.reason,
          'reason',
          ResourceFailureReason.invalidFileContent,
        ),
      );
      expect(
        await failureOf(rejected('An active owned group is required')),
        isA<ResourceFailure>().having(
          (f) => f.reason,
          'reason',
          ResourceFailureReason.groupNotActive,
        ),
      );
      expect(
        await failureOf(
          rejected('The upload reservation has expired or was cancelled'),
        ),
        isA<ResourceFailure>().having(
          (f) => f.reason,
          'reason',
          ResourceFailureReason.reservationExpired,
        ),
      );
    });

    test('transport and authentication failures', () async {
      expect(
        await failureOf(const FunctionsFetchException(details: 'offline')),
        isA<AppFailure>().having((f) => f.type, 'type', AppFailureType.network),
      );
      expect(
        await failureOf(
          const FunctionException(
            status: 401,
            details: {'error': 'invalid_access_token'},
          ),
        ),
        isA<AppFailure>().having(
          (f) => f.type,
          'type',
          AppFailureType.sessionExpired,
        ),
      );
    });

    test('RPC errors for archived groups and invalid links', () async {
      source.error = const PostgrestException(
        message: 'An active owned resource is required',
        code: '42501',
      );
      await expectLater(
        repository.updateMetadata(resourceId: 'r1', details: _details),
        throwsA(
          isA<ResourceFailure>().having(
            (f) => f.reason,
            'reason',
            ResourceFailureReason.groupNotActive,
          ),
        ),
      );

      source.error = const PostgrestException(
        message: 'A valid HTTPS URL is required',
        code: '22023',
      );
      await expectLater(
        repository.createLink(
          groupId: 'g1',
          type: ResourceType.externalLink,
          url: 'http://x',
          details: _details,
        ),
        throwsA(
          isA<ResourceFailure>().having(
            (f) => f.reason,
            'reason',
            ResourceFailureReason.invalidLink,
          ),
        ),
      );
    });
  });
}
