import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_student/features/announcements/data/student_announcements_repository_impl.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> _row({String id = 'a1', Object? reads = const []}) => {
  'id': id,
  'group_id': 'g1',
  'teacher_id': 't1',
  'title': 'موعد الاختبار',
  'body': 'راجعوا الفصل الثالث.',
  'created_at': '2026-10-05T10:00:00Z',
  'updated_at': '2026-10-05T10:00:00Z',
  'reads': reads,
};

final class _FakeDataSource implements StudentAnnouncementsRemoteDataSource {
  List<Map<String, dynamic>> rows = [];
  Object? readResult = '2026-10-08T09:00:00.5+00:00';
  Object? error;
  final fetches = <({String groupId, int offset, int limit})>[];
  final reads = <String>[];

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
  Future<Object?> markRead(String announcementId) async {
    reads.add(announcementId);
    if (error case final error?) throw error;
    return readResult;
  }
}

void main() {
  late _FakeDataSource source;
  late FakePhoneAuthService auth;
  late StudentAnnouncementsRepositoryImpl repository;

  setUp(() {
    source = _FakeDataSource();
    auth = FakePhoneAuthService(signedIn: true);
    repository = StudentAnnouncementsRepositoryImpl(source, auth);
  });

  test('embeds only read marks next to the shared columns', () {
    expect(
      SupabaseStudentAnnouncementsDataSource.columns,
      '${Announcement.columns}, reads:announcement_reads(student_id, read_at)',
    );
  });

  test('a missing read row means unread', () async {
    source.rows = [
      _row(),
      _row(id: 'a2', reads: null),
      _row(
        id: 'a3',
        reads: [
          {'student_id': testUserId, 'read_at': '2026-10-06T08:00:00Z'},
        ],
      ),
    ];

    final page = await repository.fetchAnnouncements('g1', limit: 3);
    expect(page.items.map((i) => i.isUnread), [true, true, false]);
    expect(page.items.last.readAt, DateTime.utc(2026, 10, 6, 8));
    expect(page.hasMore, isTrue);
    expect(source.fetches.single, (groupId: 'g1', offset: 0, limit: 3));
  });

  test("another student's read row never counts", () async {
    source.rows = [
      _row(
        reads: [
          {'student_id': 'someone-else', 'read_at': '2026-10-06T08:00:00Z'},
        ],
      ),
    ];
    final page = await repository.fetchAnnouncements('g1');
    expect(page.items.single.isUnread, isTrue);
  });

  test('loading the feed never marks anything read', () async {
    source.rows = [_row(), _row(id: 'a2')];
    await repository.fetchAnnouncements('g1');
    expect(source.reads, isEmpty);
  });

  test('markRead calls the RPC and returns the read time', () async {
    final readAt = await repository.markRead('a1');
    expect(source.reads, ['a1']);
    expect(readAt, DateTime.utc(2026, 10, 8, 9, 0, 0, 500));
  });

  test('a rejected markRead means the post is no longer accessible', () async {
    source.error = const PostgrestException(
      message: 'Announcement not accessible',
      code: '42501',
    );
    await expectLater(
      repository.markRead('a1'),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.type,
          'type',
          AppFailureType.notFound,
        ),
      ),
    );
  });

  test('malformed rows and missing sessions fail safely', () async {
    source.rows = [
      {'id': 'a1'},
    ];
    await expectLater(
      repository.fetchAnnouncements('g1'),
      throwsA(
        isA<AppFailure>().having((f) => f.type, 'type', AppFailureType.unknown),
      ),
    );

    source.readResult = null;
    await expectLater(
      repository.markRead('a1'),
      throwsA(
        isA<AppFailure>().having((f) => f.type, 'type', AppFailureType.unknown),
      ),
    );

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
  });
}
