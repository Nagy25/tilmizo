import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/student_classes/data/student_classes_remote_data_source.dart';
import 'package:tilmizo_student/features/student_classes/data/student_classes_repository_impl.dart';
import 'package:tilmizo_student/features/student_classes/domain/student_class.dart';

import '../../helpers/fakes.dart';

final class _Source implements StudentClassesRemoteDataSource {
  final rows = <Map<String, dynamic>>[];
  final marks = <Map<String, dynamic>>[];
  List<String>? queriedGroups;
  int calls = 0;

  @override
  Future<({List<Map<String, dynamic>> rows, int? total})> fetchSessions({
    required List<String> groupIds,
    required StudentSessionsView view,
    required DateTime now,
    required int offset,
    required int limit,
    String? groupId,
  }) async {
    calls++;
    queriedGroups = groupIds;
    final visible = rows.where((row) => groupIds.contains(row['group_id']));
    final page = visible.skip(offset).take(limit).toList();
    return (rows: page, total: visible.length);
  }

  @override
  Future<Map<String, dynamic>?> fetchSession(
    String id,
    List<String> groupIds,
  ) async {
    for (final row in rows) {
      if (row['id'] == id && groupIds.contains(row['group_id'])) return row;
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttendance(
    String studentId,
    List<String> sessionIds,
  ) async => marks
      .where(
        (row) =>
            row['student_id'] == studentId &&
            sessionIds.contains(row['session_id']),
      )
      .toList();

  @override
  Future<List<Map<String, dynamic>>> fetchSchedule(String groupId) async => [];

  @override
  Future<List<Map<String, dynamic>>> fetchGroupActivity(
    List<String> groupIds,
  ) async => [];
}

Map<String, dynamic> _session(String id, {String groupId = 'group-1'}) => {
  'id': id,
  'group_id': groupId,
  'starts_at': '2026-10-06T15:00:00+00:00',
  'ends_at': '2026-10-06T17:00:00+00:00',
  'location_type': 'physical',
  'physical_location': 'Room 2',
  'meeting_link': null,
  'status': 'scheduled',
  'notes': null,
  'group': {
    'id': groupId,
    'name': 'Physics Group',
    'subject': 'Physics',
    'grade': null,
  },
};

void main() {
  test(
    'missing attendance remains not_marked; each explicit status is preserved',
    () async {
      final source = _Source();
      source.rows.addAll([
        for (var index = 0; index < 6; index++) _session('session-$index'),
      ]);
      for (var index = 0; index < AttendanceStatus.values.length; index++) {
        source.marks.add({
          'session_id': 'session-${index + 1}',
          'student_id': testUserId,
          'status': AttendanceStatus.values[index].backendValue,
        });
      }
      source.marks.add({
        'session_id': 'session-0',
        'student_id': 'another-student',
        'status': 'absent',
      });
      final repository = StudentClassesRepositoryImpl(
        source,
        FakePhoneAuthService(signedIn: true),
      );

      final page = await repository.fetchSessions(
        approvedGroupIds: ['group-1'],
        view: StudentSessionsView.upcoming,
        now: DateTime.utc(2026, 10, 5),
        limit: 3,
      );
      expect(page.total, 6);
      expect(page.hasMore, isTrue);
      expect(page.sessions.first.attendance, AttendanceStatus.notMarked);
      final secondPage = await repository.fetchSessions(
        approvedGroupIds: ['group-1'],
        view: StudentSessionsView.upcoming,
        now: DateTime.utc(2026, 10, 5),
        offset: 3,
        limit: 3,
      );
      expect(secondPage.hasMore, isFalse);
      expect(
        [
          ...page.sessions,
          ...secondPage.sessions,
        ].skip(1).map((session) => session.attendance),
        AttendanceStatus.values,
      );
    },
  );

  test('does not fetch unapproved groups or expose their sessions', () async {
    final source = _Source()..rows.add(_session('secret', groupId: 'other'));
    final repository = StudentClassesRepositoryImpl(
      source,
      FakePhoneAuthService(signedIn: true),
    );
    final page = await repository.fetchSessions(
      approvedGroupIds: ['group-1'],
      groupId: 'other',
      view: StudentSessionsView.upcoming,
      now: DateTime.utc(2026, 10, 5),
    );
    expect(page.sessions, isEmpty);
    expect(source.calls, 0);
    expect(
      () => repository.fetchSession(
        sessionId: 'secret',
        approvedGroupIds: ['group-1'],
      ),
      throwsA(isA<AppFailure>()),
    );
  });
}
