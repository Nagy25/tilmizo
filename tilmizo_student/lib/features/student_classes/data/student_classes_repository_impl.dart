import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/student_class.dart';
import '../domain/student_classes_repository.dart';
import 'student_classes_dto.dart';
import 'student_classes_remote_data_source.dart';

final studentClassesRemoteDataSourceProvider =
    Provider<StudentClassesRemoteDataSource>(
      (ref) =>
          SupabaseStudentClassesDataSource(ref.watch(supabaseClientProvider)),
    );

final studentClassesRepositoryProvider = Provider<StudentClassesRepository>(
  (ref) => StudentClassesRepositoryImpl(
    ref.watch(studentClassesRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class StudentClassesRepositoryImpl implements StudentClassesRepository {
  StudentClassesRepositoryImpl(this._source, this._auth);

  final StudentClassesRemoteDataSource _source;
  final PhoneAuthService _auth;

  @override
  Future<StudentSessionsPage> fetchSessions({
    required List<String> approvedGroupIds,
    required StudentSessionsView view,
    required DateTime now,
    String? groupId,
    int offset = 0,
    int limit = 20,
  }) => _guard(() async {
    final studentId = requireUserId(_auth);
    if (approvedGroupIds.isEmpty ||
        (groupId != null && !approvedGroupIds.contains(groupId))) {
      return const StudentSessionsPage(sessions: [], hasMore: false, total: 0);
    }
    final response = await _source.fetchSessions(
      groupIds: approvedGroupIds,
      groupId: groupId,
      view: view,
      now: now,
      offset: offset,
      limit: limit,
    );
    final sessions = response.rows
        .map(StudentClassesDto.sessionFromRow)
        .toList();
    final marks = await _marks(studentId, [for (final s in sessions) s.id]);
    return StudentSessionsPage(
      sessions: [
        for (final session in sessions)
          session.withAttendance(
            marks[session.id] ?? AttendanceStatus.notMarked,
          ),
      ],
      hasMore: response.total == null
          ? sessions.length == limit
          : offset + sessions.length < response.total!,
      total: response.total,
    );
  });

  @override
  Future<StudentClassSession> fetchSession({
    required String sessionId,
    required List<String> approvedGroupIds,
  }) => _guard(() async {
    final studentId = requireUserId(_auth);
    if (approvedGroupIds.isEmpty) {
      throw const AppFailure(AppFailureType.notFound);
    }
    final row = await _source.fetchSession(sessionId, approvedGroupIds);
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    final session = StudentClassesDto.sessionFromRow(row);
    final marks = await _marks(studentId, [sessionId]);
    return session.withAttendance(
      marks[sessionId] ?? AttendanceStatus.notMarked,
    );
  });

  @override
  Future<List<StudentScheduleEntry>> fetchSchedule(String groupId) =>
      _guard(() async {
        requireUserId(_auth);
        final rows = await _source.fetchSchedule(groupId);
        return rows.map(StudentClassesDto.scheduleFromRow).toList();
      });

  @override
  Future<Map<String, bool>> fetchGroupActivity(List<String> groupIds) =>
      _guard(() async {
        requireUserId(_auth);
        if (groupIds.isEmpty) return {};
        final rows = await _source.fetchGroupActivity(groupIds);
        return {
          for (final row in rows) row['id'] as String: row['is_active'] as bool,
        };
      });

  Future<Map<String, AttendanceStatus>> _marks(
    String studentId,
    List<String> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return {};
    final rows = await _source.fetchAttendance(studentId, sessionIds);
    return {
      for (final row in rows)
        row['session_id'] as String: AttendanceStatus.fromBackend(
          row['status'] as String,
        ),
    };
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppFailure {
      rethrow;
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
