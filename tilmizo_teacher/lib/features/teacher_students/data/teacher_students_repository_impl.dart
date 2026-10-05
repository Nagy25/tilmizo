import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/teacher_student.dart';
import '../domain/teacher_students_repository.dart';
import 'teacher_students_dto.dart';
import 'teacher_students_remote_data_source.dart';

final teacherStudentsRemoteDataSourceProvider =
    Provider<TeacherStudentsRemoteDataSource>(
      (ref) =>
          SupabaseTeacherStudentsDataSource(ref.watch(supabaseClientProvider)),
    );

final teacherStudentsRepositoryProvider = Provider<TeacherStudentsRepository>(
  (ref) => TeacherStudentsRepositoryImpl(
    ref.watch(teacherStudentsRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class TeacherStudentsRepositoryImpl implements TeacherStudentsRepository {
  TeacherStudentsRepositoryImpl(this._source, this._auth);

  static const pageSize = 500;
  final TeacherStudentsRemoteDataSource _source;
  final PhoneAuthService _auth;

  @override
  Future<List<TeacherStudent>> fetchAllStudents() async {
    try {
      final teacherId = requireUserId(_auth);
      final rows = <Map<String, dynamic>>[];
      String? afterId;
      while (true) {
        final page = await _source.fetchPage(
          teacherId: teacherId,
          limit: pageSize,
          afterId: afterId,
        );
        if (page.isEmpty) break;
        rows.addAll(page);
        final nextId = page.last['id'] as String;
        if (nextId == afterId) throw const FormatException('Repeated page');
        afterId = nextId;
        if (page.length < pageSize) break;
      }
      return TeacherStudentsDto.aggregate(rows);
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
