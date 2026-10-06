import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/attendance_repository.dart';
import '../domain/attendance_roster.dart';
import 'attendance_remote_data_source.dart';

final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>(
  (ref) => SupabaseAttendanceDataSource(ref.watch(supabaseClientProvider)),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(
    ref.watch(attendanceRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._dataSource, this._auth);

  static const pageSize = 500;

  final AttendanceRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<AttendanceRoster> fetchRoster({
    required String groupId,
    required String sessionId,
  }) => _guard(() async {
    final teacherId = requireUserId(_auth);
    final results = await Future.wait([
      _fetchAllMemberships(teacherId, groupId),
      _dataSource.fetchAttendance(sessionId),
    ]);
    final saved = {
      for (final row in results[1])
        row['student_id'] as String: AttendanceStatus.fromBackend(
          row['status'] as String,
        ),
    };

    final current = <AttendanceStudent>[];
    final former = <AttendanceStudent>[];
    for (final row in results[0]) {
      final studentId = row['student_id'] as String;
      final isActive =
          MembershipStatus.fromBackend(row['status'] as String) ==
          MembershipStatus.active;
      final savedStatus = saved[studentId];
      if (!isActive && savedStatus == null) continue;
      final profile = row['student'] as Map<String, dynamic>;
      final student = AttendanceStudent(
        studentId: studentId,
        studentName: profile['full_name'] as String?,
        studentPhone: profile['phone'] as String,
        savedStatus: savedStatus ?? AttendanceStatus.notMarked,
      );
      (isActive ? current : former).add(student);
    }
    int byName(AttendanceStudent a, AttendanceStudent b) =>
        a.displayName.compareTo(b.displayName);
    return AttendanceRoster(
      current: current..sort(byName),
      former: former..sort(byName),
    );
  });

  @override
  Future<AttendanceStatus> setAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) => _guard(() async {
    requireUserId(_auth);
    final row = await _dataSource.setAttendance(
      sessionId: sessionId,
      studentId: studentId,
      status: status.backendValue,
    );
    return AttendanceStatus.fromBackend(row['status'] as String);
  });

  Future<List<Map<String, dynamic>>> _fetchAllMemberships(
    String teacherId,
    String groupId,
  ) async {
    final rows = <Map<String, dynamic>>[];
    String? afterId;
    while (true) {
      final page = await _dataSource.fetchMembershipPage(
        teacherId: teacherId,
        groupId: groupId,
        limit: pageSize,
        afterId: afterId,
      );
      rows.addAll(page);
      if (page.length < pageSize) return rows;
      afterId = page.last['id'] as String;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
