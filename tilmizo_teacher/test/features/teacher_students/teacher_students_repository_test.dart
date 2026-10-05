import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/teacher_students/data/teacher_students_remote_data_source.dart';
import 'package:tilmizo_teacher/features/teacher_students/data/teacher_students_repository_impl.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> membershipRow({
  required String id,
  required String studentId,
  required String groupId,
  required String groupName,
  String status = 'active',
  String name = 'طالب',
  String joined = '2026-10-01T09:00:00+00:00',
}) => {
  'id': id,
  'student_id': studentId,
  'status': status,
  'joined_at': joined,
  'student': {'full_name': name, 'phone': '+201012345678'},
  'owner': {'id': groupId, 'name': groupName, 'teacher_id': testUserId},
};

final class _FakeSource implements TeacherStudentsRemoteDataSource {
  final rows = <Map<String, dynamic>>[];
  final calls = <({String teacherId, String? afterId, int limit})>[];
  Object? error;

  @override
  Future<List<Map<String, dynamic>>> fetchPage({
    required String teacherId,
    required int limit,
    String? afterId,
  }) async {
    calls.add((teacherId: teacherId, afterId: afterId, limit: limit));
    if (error case final error?) throw error;
    return rows
        .where(
          (row) =>
              afterId == null || (row['id'] as String).compareTo(afterId) > 0,
        )
        .take(limit)
        .toList();
  }
}

void main() {
  late _FakeSource source;
  late TeacherStudentsRepositoryImpl repository;

  setUp(() {
    source = _FakeSource();
    repository = TeacherStudentsRepositoryImpl(
      source,
      FakePhoneAuthService(signedIn: true),
    );
  });

  test(
    'deduplicates students across active, suspended, and archived groups',
    () async {
      source.rows.addAll([
        membershipRow(
          id: 'm1',
          studentId: 's1',
          groupId: 'g1',
          groupName: 'الفيزياء',
          joined: '2026-10-02T09:00:00+00:00',
        ),
        membershipRow(
          id: 'm2',
          studentId: 's1',
          groupId: 'g2',
          groupName: 'الرياضيات',
          status: 'suspended',
          joined: '2026-10-01T09:00:00+00:00',
        ),
        membershipRow(
          id: 'm3',
          studentId: 's2',
          groupId: 'g2',
          groupName: 'الرياضيات',
          status: 'removed',
        ),
      ]);

      final students = await repository.fetchAllStudents();
      expect(students, hasLength(1));
      expect(students.single.groupCount, 2);
      expect(students.single.hasActiveMembership, isTrue);
      expect(students.single.firstJoinedAt, DateTime.utc(2026, 10, 1, 9));
      expect(source.calls.single.teacherId, testUserId);
    },
  );

  test('reads beyond one page with a stable membership cursor', () async {
    for (var i = 0; i < 501; i++) {
      final id = 'm${i.toString().padLeft(4, '0')}';
      source.rows.add(
        membershipRow(
          id: id,
          studentId: 's$i',
          groupId: 'g1',
          groupName: 'الفيزياء',
        ),
      );
    }
    final students = await repository.fetchAllStudents();
    expect(students, hasLength(501));
    expect(source.calls, hasLength(2));
    expect(source.calls.last.afterId, 'm0499');
    expect(source.calls.first.limit, 500);
  });

  test('maps transport failure without exposing raw errors', () {
    source.error = TimeoutException('slow');
    expect(
      repository.fetchAllStudents(),
      throwsA(
        isA<AppFailure>().having(
          (error) => error.type,
          'type',
          AppFailureType.network,
        ),
      ),
    );
  });
}
