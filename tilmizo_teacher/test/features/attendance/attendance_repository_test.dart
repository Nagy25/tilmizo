import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/attendance/data/attendance_remote_data_source.dart';
import 'package:tilmizo_teacher/features/attendance/data/attendance_repository_impl.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> memberRow(String id, String status, {String? name}) => {
  'id': 'm-$id',
  'student_id': id,
  'status': status,
  'student': {'full_name': name, 'phone': '+20100000000$id'},
};

final class _FakeAttendanceDataSource implements AttendanceRemoteDataSource {
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> attendance = [];
  final rpcCalls = <Map<String, String>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchMembershipPage({
    required String teacherId,
    required String groupId,
    required int limit,
    String? afterId,
  }) async => afterId == null ? members : [];

  @override
  Future<List<Map<String, dynamic>>> fetchAttendance(String sessionId) async =>
      attendance;

  @override
  Future<Map<String, dynamic>> setAttendance({
    required String sessionId,
    required String studentId,
    required String status,
  }) async {
    rpcCalls.add({
      'session': sessionId,
      'student': studentId,
      'status': status,
    });
    return {'student_id': studentId, 'status': status};
  }
}

void main() {
  late _FakeAttendanceDataSource source;
  late AttendanceRepositoryImpl repository;

  setUp(() {
    source = _FakeAttendanceDataSource();
    repository = AttendanceRepositoryImpl(
      source,
      FakePhoneAuthService(signedIn: true),
    );
  });

  test(
    'missing rows are not marked and history of former students is kept',
    () async {
      source.members = [
        memberRow('1', 'active', name: 'ب'),
        memberRow('2', 'active', name: 'أ'),
        memberRow('3', 'removed', name: 'ج'),
        memberRow('4', 'suspended', name: 'د'),
      ];
      source.attendance = [
        {'student_id': '1', 'status': 'late'},
        {'student_id': '3', 'status': 'absent'},
      ];

      final roster = await repository.fetchRoster(
        groupId: 'group-1',
        sessionId: 's1',
      );

      expect(roster.current.map((s) => s.studentId), ['2', '1']);
      expect(roster.current.first.savedStatus, AttendanceStatus.notMarked);
      expect(roster.current.last.savedStatus, AttendanceStatus.late);
      expect(roster.former.map((s) => s.studentId), ['3']);
      expect(roster.former.single.savedStatus, AttendanceStatus.absent);
    },
  );

  test('writes go through set_session_attendance values', () async {
    final status = await repository.setAttendance(
      sessionId: 's1',
      studentId: '1',
      status: AttendanceStatus.notMarked,
    );
    expect(status, AttendanceStatus.notMarked);
    expect(source.rpcCalls.single, {
      'session': 's1',
      'student': '1',
      'status': 'not_marked',
    });
  });
}
