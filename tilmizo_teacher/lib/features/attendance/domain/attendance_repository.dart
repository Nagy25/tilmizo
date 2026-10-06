import 'package:core_package/core_package.dart';

import 'attendance_roster.dart';

/// Teacher-marked attendance. Implementations throw only `AppFailure`.
abstract interface class AttendanceRepository {
  Future<AttendanceRoster> fetchRoster({
    required String groupId,
    required String sessionId,
  });

  /// Saves one student's mark through `set_session_attendance` and returns
  /// the stored status.
  Future<AttendanceStatus> setAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  });
}
