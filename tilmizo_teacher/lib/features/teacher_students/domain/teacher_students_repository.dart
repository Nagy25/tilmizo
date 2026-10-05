import 'teacher_student.dart';

abstract interface class TeacherStudentsRepository {
  /// Unique students with an active or suspended membership in owned groups.
  Future<List<TeacherStudent>> fetchAllStudents();
}
