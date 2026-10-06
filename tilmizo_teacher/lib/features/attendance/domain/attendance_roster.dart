import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// A student listed on a session's attendance sheet with the saved mark.
@immutable
final class AttendanceStudent {
  const AttendanceStudent({
    required this.studentId,
    required this.studentPhone,
    required this.savedStatus,
    this.studentName,
  });

  final String studentId;
  final String? studentName;
  final String studentPhone;

  /// The saved mark; [AttendanceStatus.notMarked] when no row exists.
  final AttendanceStatus savedStatus;

  String get displayName => studentName ?? studentPhone;

  @override
  bool operator ==(Object other) =>
      other is AttendanceStudent &&
      other.studentId == studentId &&
      other.studentName == studentName &&
      other.studentPhone == studentPhone &&
      other.savedStatus == savedStatus;

  @override
  int get hashCode =>
      Object.hash(studentId, studentName, studentPhone, savedStatus);
}

/// Who can be marked for one session.
@immutable
final class AttendanceRoster {
  const AttendanceRoster({required this.current, required this.former});

  /// Students with an active membership in the group.
  final List<AttendanceStudent> current;

  /// Students no longer active in the group who already have a saved row
  /// for this session; kept so history is never hidden.
  final List<AttendanceStudent> former;

  List<AttendanceStudent> get all => [...current, ...former];
}
