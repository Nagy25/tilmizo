import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_teacher/features/announcements/data/announcements_remote_data_source.dart';
import 'package:tilmizo_teacher/features/announcements/data/announcements_repository_impl.dart';
import 'package:tilmizo_teacher/features/announcements/domain/announcements_repository.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> announcementRow({
  String id = 'a1',
  String title = 'موعد الاختبار',
  String updatedAt = '2026-10-05T10:00:00Z',
}) => {
  'id': id,
  'group_id': 'g1',
  'teacher_id': 't1',
  'title': title,
  'body': 'راجعوا الفصل الثالث.',
  'created_at': '2026-10-05T10:00:00Z',
  'updated_at': updatedAt,
};

final class _FakeDataSource implements AnnouncementsRemoteDataSource {
  List<Map<String, dynamic>> rows = [];
  Object? rpcResult;
  Object? error;
  final fetches = <({String groupId, int offset, int limit})>[];
  final rpcs = <(String, Map<String, dynamic>)>[];

  @override
  Future<List<Map<String, dynamic>>> fetchAnnouncements(
    String groupId, {
    required int offset,
    required int limit,
  }) async {
    fetches.add((groupId: groupId, offset: offset, limit: limit));
    if (error case final error?) throw error;
    return rows;
  }

  @override
  Future<Object?> rpc(String function, Map<String, dynamic> params) async {
    rpcs.add((function, params));
    if (error case final error?) throw error;
    return rpcResult;
  }
}

void main() {
  late _FakeDataSource source;
  late FakePhoneAuthService auth;
  late AnnouncementsRepositoryImpl repository;

  setUp(() {
    source = _FakeDataSource();
    auth = FakePhoneAuthService(signedIn: true);
    repository = AnnouncementsRepositoryImpl(source, auth);
  });

  const draft = AnnouncementDraft(
    title: '  موعد الاختبار  ',
    body: '\nراجعوا الفصل الثالث.\n',
  );

  test('reads one page and reports whether more may exist', () async {
    source.rows = [
      announcementRow(),
      announcementRow(id: 'a2', updatedAt: '2026-10-06T08:00:00Z'),
    ];

    final page = await repository.fetchAnnouncements('g1', limit: 2);
    expect(source.fetches.single, (groupId: 'g1', offset: 0, limit: 2));
    expect(page.announcements.map((a) => a.id), ['a1', 'a2']);
    expect(page.announcements.last.isEdited, isTrue);
    expect(page.hasMore, isTrue);

    final last = await repository.fetchAnnouncements('g1', offset: 2);
    expect(source.fetches.last.offset, 2);
    expect(last.hasMore, isFalse);
  });

  test('creates through create_announcement with trimmed text only', () async {
    source.rpcResult = announcementRow();

    final created = await repository.createAnnouncement('g1', draft);
    expect(created.id, 'a1');
    // The backend trigger notifies students; the client makes exactly one
    // call and has no notification API at all.
    expect(source.rpcs, hasLength(1));
    expect(source.rpcs.single.$1, 'create_announcement');
    expect(source.rpcs.single.$2, {
      'p_group_id': 'g1',
      'p_title': 'موعد الاختبار',
      'p_body': 'راجعوا الفصل الثالث.',
    });
  });

  test('deletes through delete_announcement; there is no edit', () async {
    await repository.deleteAnnouncement('a1');
    expect(source.rpcs.single.$1, 'delete_announcement');
    expect(source.rpcs.single.$2, {'p_announcement_id': 'a1'});
  });

  test('rejects blank or oversized text before calling the backend', () async {
    for (final invalid in [
      const AnnouncementDraft(title: '   ', body: 'نص'),
      const AnnouncementDraft(title: 'عنوان', body: '\n '),
      AnnouncementDraft(title: 'ع' * 201, body: 'نص'),
      AnnouncementDraft(title: 'عنوان', body: 'ن' * 10001),
      // Postgres counts code points, so 201 emoji exceed the title limit
      // and 200 fit, although each is two UTF-16 units in Dart.
      AnnouncementDraft(title: '😀' * 201, body: 'نص'),
    ]) {
      await expectLater(
        repository.createAnnouncement('g1', invalid),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.type,
            'type',
            AppFailureType.invalidInput,
          ),
        ),
      );
    }
    expect(source.rpcs, isEmpty);

    source.rpcResult = announcementRow();
    await repository.createAnnouncement(
      'g1',
      AnnouncementDraft(title: '😀' * 200, body: 'ن' * 10000),
    );
    expect(source.rpcs, hasLength(1));
  });

  test('requires a signed-in teacher', () async {
    auth.isSignedIn = false;
    await expectLater(
      repository.fetchAnnouncements('g1'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.type,
          'type',
          AppFailureType.sessionExpired,
        ),
      ),
    );
    expect(source.fetches, isEmpty);
  });

  test('maps backend failures to safe categories', () async {
    Future<AppFailureType> failureFor(Object error) async {
      source.error = error;
      try {
        await repository.createAnnouncement('g1', draft);
      } on AppFailure catch (failure) {
        return failure.type;
      }
      fail('expected a failure');
    }

    expect(
      await failureFor(
        const PostgrestException(
          message: 'Group is not writable',
          code: '42501',
        ),
      ),
      AppFailureType.notEligible,
    );
    expect(
      await failureFor(
        const PostgrestException(
          message: 'Announcement not found',
          code: 'P0002',
        ),
      ),
      AppFailureType.notFound,
    );
    expect(
      await failureFor(
        const PostgrestException(message: 'check violation', code: '23514'),
      ),
      AppFailureType.invalidInput,
    );
    expect(
      await failureFor(http.ClientException('offline')),
      AppFailureType.network,
    );
    source
      ..error = null
      ..rpcResult = {'id': 'a1'};
    await expectLater(
      repository.createAnnouncement('g1', draft),
      throwsA(
        isA<AppFailure>().having((f) => f.type, 'type', AppFailureType.unknown),
      ),
    );
  });
}
