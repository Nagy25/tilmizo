import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

@immutable
final class TeacherStudentMembership {
  const TeacherStudentMembership({
    required this.groupId,
    required this.groupName,
    required this.status,
    required this.joinedAt,
  });

  final String groupId;
  final String groupName;
  final MembershipStatus status;
  final DateTime joinedAt;
}

/// One student across all of the teacher's active or suspended memberships.
@immutable
final class TeacherStudent {
  const TeacherStudent({
    required this.id,
    required this.phone,
    required this.memberships,
    this.name,
  });

  final String id;
  final String? name;
  final String phone;
  final List<TeacherStudentMembership> memberships;

  int get groupCount => memberships.length;
  bool get hasActiveMembership => memberships.any(
    (membership) => membership.status == MembershipStatus.active,
  );

  DateTime get firstJoinedAt => memberships
      .map((membership) => membership.joinedAt)
      .reduce(
        (earliest, joined) => joined.isBefore(earliest) ? joined : earliest,
      );
}
