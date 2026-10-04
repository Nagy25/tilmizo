import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

import 'student_device.dart';

/// A student's membership in one group. Suspension affects only this group.
@immutable
final class GroupMember {
  const GroupMember({
    required this.membershipId,
    required this.groupId,
    required this.studentPhone,
    required this.status,
    required this.joinedAt,
    required this.updatedAt,
    this.studentName,
    this.approvedDevice,
  });

  final String membershipId;
  final String groupId;
  final String? studentName;
  final String studentPhone;
  final MembershipStatus status;

  /// The approved device; absent once access is suspended or removed.
  final StudentDevice? approvedDevice;
  final DateTime joinedAt;
  final DateTime updatedAt;

  bool get isActive => status == MembershipStatus.active;

  @override
  bool operator ==(Object other) =>
      other is GroupMember &&
      other.membershipId == membershipId &&
      other.groupId == groupId &&
      other.studentName == studentName &&
      other.studentPhone == studentPhone &&
      other.status == status &&
      other.approvedDevice == approvedDevice &&
      other.joinedAt == joinedAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    membershipId,
    groupId,
    studentName,
    studentPhone,
    status,
    approvedDevice,
    joinedAt,
    updatedAt,
  );
}
