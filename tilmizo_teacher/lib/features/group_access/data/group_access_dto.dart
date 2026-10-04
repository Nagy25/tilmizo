import 'package:core_package/core_package.dart';

import '../domain/access_decision_result.dart';
import '../domain/group_member.dart';
import '../domain/student_device.dart';
import '../domain/student_join_request.dart';

/// Column mapping for group access reads. Only safe display columns are ever
/// selected: never session IDs or installation hashes.
abstract final class GroupAccessDto {
  static const _student =
      'student:profiles!group_join_requests_student_id_fkey(full_name, phone)';
  static const _requestDevice =
      'device:student_devices!group_join_requests_device_id_fkey'
      '(device_name, platform, app_version)';

  static const requestColumns =
      'id, group_id, request_type, status, created_at, $_student, '
      '$_requestDevice, owner:groups!inner(teacher_id)';

  static const memberColumns =
      'id, group_id, status, joined_at, updated_at, '
      'student:profiles!group_memberships_student_id_fkey(full_name, phone), '
      'device:student_devices!group_memberships_approved_device_id_fkey'
      '(device_name, platform, app_version), '
      'owner:groups!inner(teacher_id)';

  static StudentJoinRequest requestFromRow(Map<String, dynamic> row) {
    final student = row['student'] as Map<String, dynamic>;
    return StudentJoinRequest(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      studentName: student['full_name'] as String?,
      studentPhone: student['phone'] as String,
      device: _device(row['device'] as Map<String, dynamic>),
      type: JoinRequestType.fromBackend(row['request_type'] as String),
      status: JoinRequestStatus.fromBackend(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static GroupMember memberFromRow(Map<String, dynamic> row) {
    final student = row['student'] as Map<String, dynamic>;
    final status = MembershipStatus.fromBackend(row['status'] as String);
    final device = row['device'] as Map<String, dynamic>?;
    return GroupMember(
      membershipId: row['id'] as String,
      groupId: row['group_id'] as String,
      studentName: student['full_name'] as String?,
      studentPhone: student['phone'] as String,
      status: status,
      approvedDevice: status == MembershipStatus.active && device != null
          ? _device(device)
          : null,
      joinedAt: DateTime.parse(row['joined_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static AccessDecisionResult decisionFromJson(Map<String, dynamic> json) =>
      AccessDecisionResult(
        status: JoinRequestStatus.fromBackend(json['status'] as String),
        replacedPreviousDevice: json['replaced_previous_device'] == true,
      );

  static StudentDevice _device(Map<String, dynamic> row) => StudentDevice(
    name: row['device_name'] as String,
    platform: DevicePlatform.fromBackend(row['platform'] as String),
    appVersion: row['app_version'] as String?,
  );
}
