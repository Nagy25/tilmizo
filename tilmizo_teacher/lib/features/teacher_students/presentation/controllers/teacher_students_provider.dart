import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/teacher_students_repository_impl.dart';
import '../../domain/teacher_student.dart';

final teacherStudentsProvider =
    FutureProvider.autoDispose<List<TeacherStudent>>(
      (ref) => ref.watch(teacherStudentsRepositoryProvider).fetchAllStudents(),
    );
