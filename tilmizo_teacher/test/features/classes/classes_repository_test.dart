import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_teacher/features/classes/data/classes_remote_data_source.dart';
import 'package:tilmizo_teacher/features/classes/data/classes_repository_impl.dart';
import 'package:tilmizo_teacher/features/classes/domain/classes_repository.dart';
import 'package:tilmizo_teacher/features/classes/domain/one_time_session_draft.dart';
import 'package:tilmizo_teacher/features/classes/domain/schedule_entry.dart';
import 'package:tilmizo_teacher/features/classes/domain/session_location.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> sessionRow(String id, {String status = 'scheduled'}) => {
  'id': id,
  'group_id': 'group-1',
  'schedule_entry_id': null,
  'starts_at': '2026-10-01T14:00:00+00:00',
  'ends_at': '2026-10-01T15:30:00+00:00',
  'location_type': 'online',
  'physical_location': null,
  'meeting_link': 'https://meet.example.com/abc',
  'status': status,
  'notes': null,
  'group': {
    'id': 'group-1',
    'name': 'مجموعة التفوق',
    'subject': 'فيزياء',
    'is_active': true,
    'teacher_id': testUserId,
  },
};

Map<String, dynamic> entryRow(String id) => {
  'id': id,
  'group_id': 'group-1',
  'weekday': 7,
  'start_time': '17:00:00',
  'end_time': '18:30:00',
  'location_type': 'physical',
  'physical_location': 'سنتر الأوائل',
  'meeting_link': null,
  'is_active': true,
};

final class _FakeClassesDataSource implements ClassesRemoteDataSource {
  List<Map<String, dynamic>> rows = [];
  Map<String, dynamic>? single;
  Object? error;
  final calls = <String>[];
  Object? lastPayload;

  Future<T> _run<T>(String call, T value) async {
    calls.add(call);
    if (error case final error?) throw error;
    return value;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSessions({
    required String teacherId,
    required SessionsView view,
    required DateTime now,
    required int offset,
    required int limit,
    String? groupId,
  }) => _run('sessions:$teacherId:${view.name}:$groupId:$offset:$limit', rows);

  @override
  Future<Map<String, dynamic>?> fetchSession(String teacherId, String id) =>
      _run('session:$teacherId:$id', single);

  @override
  Future<Map<String, dynamic>> createManualSession(
    Map<String, dynamic> params,
  ) {
    lastPayload = params;
    return _run('create', sessionRow('new'));
  }

  @override
  Future<Map<String, dynamic>> createManualSessionWithPayment(
    Map<String, dynamic> params,
  ) {
    lastPayload = params;
    return _run('createWithPayment', sessionRow('paid'));
  }

  @override
  Future<Map<String, dynamic>?> updateSession(
    String id,
    Map<String, dynamic> payload,
  ) {
    lastPayload = payload;
    return _run('update:$id', single);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveEntries(
    String teacherId,
    String groupId,
  ) => _run('entries:$teacherId:$groupId', rows);

  @override
  Future<Map<String, dynamic>?> fetchEntry(String teacherId, String id) =>
      _run('entry:$teacherId:$id', single);

  @override
  Future<void> insertEntries(List<Map<String, dynamic>> rows) {
    lastPayload = rows;
    return _run('insertEntries', null);
  }

  @override
  Future<Map<String, dynamic>?> updateEntry(
    String id,
    Map<String, dynamic> payload,
  ) {
    lastPayload = payload;
    return _run('updateEntry:$id', single);
  }
}

void main() {
  late _FakeClassesDataSource source;
  late ClassesRepositoryImpl repository;

  setUp(() {
    source = _FakeClassesDataSource();
    repository = ClassesRepositoryImpl(
      source,
      FakePhoneAuthService(signedIn: true),
    );
  });

  test('parses session rows with the group snapshot', () async {
    source.rows = [sessionRow('s1')];
    final page = await repository.fetchSessions(
      view: SessionsView.upcoming,
      now: testTime,
      limit: 1,
    );
    final session = page.sessions.single;
    expect(page.hasMore, isTrue);
    expect(session.group.name, 'مجموعة التفوق');
    expect(session.location.meetingLink, 'https://meet.example.com/abc');
    expect(session.startsAt, DateTime.utc(2026, 10, 1, 14));
    expect(source.calls.single, 'sessions:$testUserId:upcoming:null:0:1');
  });

  test('creates one-time sessions through the RPC parameter names', () async {
    source.single = sessionRow('new');
    await repository.createOneTimeSession(
      OneTimeSessionDraft(
        groupId: 'group-1',
        startsAt: DateTime.utc(2026, 10, 2, 14),
        endsAt: DateTime.utc(2026, 10, 2, 15),
        location: const SessionLocation.physical('قاعة 3'),
        notes: 'إحضار الكراسة',
      ),
    );
    expect(source.lastPayload, {
      'p_group_id': 'group-1',
      'p_starts_at': '2026-10-02T14:00:00.000Z',
      'p_ends_at': '2026-10-02T15:00:00.000Z',
      'p_location_type': 'physical',
      'p_physical_location': 'قاعة 3',
      'p_meeting_link': null,
      'p_notes': 'إحضار الكراسة',
    });
    expect(source.calls, ['create', 'session:$testUserId:new']);
  });

  test('a session with an amount uses the atomic payment RPC', () async {
    source.single = sessionRow('paid');
    await repository.createOneTimeSession(
      OneTimeSessionDraft(
        groupId: 'group-1',
        startsAt: DateTime.utc(2026, 10, 2, 14),
        endsAt: DateTime.utc(2026, 10, 2, 15),
        location: const SessionLocation.online('https://meet.example.com/x'),
        paymentAmount: const EgpAmount.piasters(12050),
      ),
    );
    expect(source.calls, ['createWithPayment', 'session:$testUserId:paid']);
    expect(source.lastPayload, {
      'p_group_id': 'group-1',
      'p_starts_at': '2026-10-02T14:00:00.000Z',
      'p_ends_at': '2026-10-02T15:00:00.000Z',
      'p_location_type': 'online',
      'p_physical_location': null,
      'p_meeting_link': 'https://meet.example.com/x',
      'p_notes': null,
      'p_payment_amount': 120.5,
    });
  });

  test('session writes send only teacher-writable columns', () async {
    source.single = sessionRow('s1', status: 'cancelled');
    await repository.setSessionStatus('s1', SessionStatus.cancelled);
    expect(source.lastPayload, {'status': 'cancelled'});

    await repository.changeSessionLocation(
      's1',
      const SessionLocation.online('https://meet.example.com/x'),
    );
    expect(source.lastPayload, {
      'location_type': 'online',
      'physical_location': null,
      'meeting_link': 'https://meet.example.com/x',
    });

    await repository.updateSessionNotes('s1', '   ');
    expect(source.lastPayload, {'notes': null});
  });

  test('a missing updated session is reported as not found', () async {
    source.single = null;
    await expectLater(
      repository.setSessionStatus('s1', SessionStatus.completed),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.type,
          'type',
          AppFailureType.notFound,
        ),
      ),
    );
  });

  test('saves weekly slots in one insert with Postgres time values', () async {
    await repository.createScheduleEntries('group-1', const [
      WeeklySlot(
        weekday: 6,
        start: ClockTime(17, 0),
        end: ClockTime(18, 30),
        location: SessionLocation.physical('سنتر'),
      ),
      WeeklySlot(
        weekday: 2,
        start: ClockTime(9, 5),
        end: ClockTime(10, 0),
        location: SessionLocation.online('https://meet.example.com/a'),
      ),
    ]);
    expect(source.calls, ['insertEntries']);
    final rows = source.lastPayload! as List;
    expect(rows.first, {
      'group_id': 'group-1',
      'weekday': 6,
      'start_time': '17:00:00',
      'end_time': '18:30:00',
      'location_type': 'physical',
      'physical_location': 'سنتر',
      'meeting_link': null,
    });
    expect((rows.last as Map)['start_time'], '09:05:00');
  });

  test('a duplicate active slot is reported as a schedule conflict', () async {
    source.error = const PostgrestException(
      message: 'duplicate key value',
      code: '23505',
    );
    await expectLater(
      repository.createScheduleEntries('group-1', const [
        WeeklySlot(
          weekday: 1,
          start: ClockTime(17, 0),
          end: ClockTime(18, 0),
          location: SessionLocation.physical('سنتر'),
        ),
      ]),
      throwsA(isA<ScheduleConflict>()),
    );
  });

  test('parses schedule entries and deactivates without deleting', () async {
    source.rows = [entryRow('e1')];
    final entry = (await repository.fetchScheduleEntries('group-1')).single;
    expect(entry.slot.weekday, 7);
    expect(entry.slot.start, const ClockTime(17, 0));
    expect(entry.slot.location.physicalLocation, 'سنتر الأوائل');

    source.single = {...entryRow('e1'), 'is_active': false};
    await repository.deactivateScheduleEntry('e1');
    expect(source.lastPayload, {'is_active': false});
  });

  test('unknown backend values never leak raw errors', () async {
    source.rows = [sessionRow('s1', status: 'postponed')];
    await expectLater(
      repository.fetchSessions(view: SessionsView.past, now: testTime),
      throwsA(
        isA<AppFailure>().having((f) => f.type, 'type', AppFailureType.unknown),
      ),
    );
  });

  test('location validation mirrors the database checks', () {
    expect(
      SessionLocation.validate(SessionLocationType.online, 'http://x.com'),
      SessionLocationIssue.invalidLink,
    );
    expect(
      SessionLocation.validate(SessionLocationType.online, 'https://'),
      SessionLocationIssue.invalidLink,
    );
    expect(
      SessionLocation.validate(SessionLocationType.online, 'https://a.b/c d'),
      SessionLocationIssue.invalidLink,
    );
    expect(
      SessionLocation.validate(SessionLocationType.online, ' https://a.com '),
      isNull,
    );
    expect(
      SessionLocation.validate(SessionLocationType.physical, '  '),
      SessionLocationIssue.missingPlace,
    );
    expect(
      SessionLocation.validate(SessionLocationType.physical, 'x' * 501),
      SessionLocationIssue.placeTooLong,
    );
  });
}
