import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

import 'student_device.dart';

/// A student's request to join a group or to replace their approved device.
@immutable
final class StudentJoinRequest {
  const StudentJoinRequest({
    required this.id,
    required this.groupId,
    required this.studentPhone,
    required this.device,
    required this.type,
    required this.status,
    required this.createdAt,
    this.studentName,
  });

  final String id;
  final String groupId;
  final String? studentName;

  /// Egyptian E.164 number; display it masked.
  final String studentPhone;
  final StudentDevice device;
  final JoinRequestType type;
  final JoinRequestStatus status;
  final DateTime createdAt;

  bool get isReplacement => type == JoinRequestType.deviceReplacement;

  @override
  bool operator ==(Object other) =>
      other is StudentJoinRequest &&
      other.id == id &&
      other.groupId == groupId &&
      other.studentName == studentName &&
      other.studentPhone == studentPhone &&
      other.device == device &&
      other.type == type &&
      other.status == status &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    studentName,
    studentPhone,
    device,
    type,
    status,
    createdAt,
  );
}
