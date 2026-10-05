import 'package:core_package/core_package.dart';
import 'package:tilmizo_teacher/features/teacher_students/domain/teacher_student.dart';
import 'package:tilmizo_teacher/features/teacher_students/domain/teacher_students_repository.dart';

final class FakeTeacherStudentsRepository implements TeacherStudentsRepository {
  FakeTeacherStudentsRepository([List<TeacherStudent>? students])
    : students = [...?students];

  final List<TeacherStudent> students;
  AppFailure? fetchFailure;
  int fetchCount = 0;

  @override
  Future<List<TeacherStudent>> fetchAllStudents() async {
    fetchCount++;
    if (fetchFailure case final failure?) throw failure;
    return [...students];
  }
}

TeacherStudent buildTeacherStudent({
  String id = 'student-1',
  String? name = 'عمر أحمد',
  String phone = '+201012345678',
  List<TeacherStudentMembership>? memberships,
}) => TeacherStudent(
  id: id,
  name: name,
  phone: phone,
  memberships:
      memberships ??
      [
        TeacherStudentMembership(
          groupId: 'group-1',
          groupName: 'مجموعة التفوق',
          status: MembershipStatus.active,
          joinedAt: DateTime.utc(2026, 10, 1),
        ),
      ],
);
