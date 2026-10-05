import 'package:core_package/core_package.dart';

import '../domain/teacher_student.dart';

abstract final class TeacherStudentsDto {
  static List<TeacherStudent> aggregate(List<Map<String, dynamic>> rows) {
    final students = <String, _StudentAccumulator>{};
    for (final row in rows) {
      final status = MembershipStatus.fromBackend(row['status'] as String);
      if (status == MembershipStatus.removed) continue;
      final studentId = row['student_id'] as String;
      final profile = row['student'] as Map<String, dynamic>;
      final group = row['owner'] as Map<String, dynamic>;
      final accumulator = students.putIfAbsent(
        studentId,
        () => _StudentAccumulator(
          id: studentId,
          name: profile['full_name'] as String?,
          phone: profile['phone'] as String,
        ),
      );
      accumulator.memberships[group['id'] as String] = TeacherStudentMembership(
        groupId: group['id'] as String,
        groupName: group['name'] as String,
        status: status,
        joinedAt: DateTime.parse(row['joined_at'] as String),
      );
    }
    final result = [
      for (final student in students.values)
        TeacherStudent(
          id: student.id,
          name: student.name,
          phone: student.phone,
          memberships: List.unmodifiable(
            student.memberships.values.toList()
              ..sort((a, b) => a.groupName.compareTo(b.groupName)),
          ),
        ),
    ];
    result.sort((a, b) {
      final byName = (a.name ?? a.phone).compareTo(b.name ?? b.phone);
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
    return List.unmodifiable(result);
  }
}

final class _StudentAccumulator {
  _StudentAccumulator({
    required this.id,
    required this.name,
    required this.phone,
  });

  final String id;
  final String? name;
  final String phone;
  final Map<String, TeacherStudentMembership> memberships = {};
}
