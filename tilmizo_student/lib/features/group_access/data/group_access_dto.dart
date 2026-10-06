import 'package:core_package/core_package.dart';

import '../domain/approved_group.dart';
import '../domain/backend_access_state.dart';
import '../domain/group_access_entry.dart';
import '../domain/join_request_outcome.dart';

abstract final class GroupAccessDto {
  static const approvedGroupColumns =
      'id, name, subject, grade, is_active, invite_code';

  static GroupAccessEntry entryFromRow(Map<String, dynamic> row) {
    T? parse<T>(String key, T Function(String) parser) {
      final value = row[key];
      return value == null ? null : parser(value as String);
    }

    final changed = row['updated_at'] as String?;
    return GroupAccessEntry(
      groupId: row['group_id'] as String,
      groupName: row['group_name'] as String,
      subject: row['subject'] as String?,
      grade: row['grade'] as String?,
      teacherName: row['teacher_name'] as String?,
      membershipId: row['membership_id'] as String?,
      membershipStatus: parse(
        'membership_status',
        MembershipStatus.fromBackend,
      ),
      approvedDeviceName: row['approved_device_name'] as String?,
      latestRequestId: row['latest_request_id'] as String?,
      requestStatus: parse(
        'latest_request_status',
        JoinRequestStatus.fromBackend,
      ),
      requestType: parse('latest_request_type', JoinRequestType.fromBackend),
      requestFromCurrentSession:
          row['latest_request_is_current_session'] == true,
      currentSessionApproved: row['is_current_session_approved'] == true,
      canRequestDeviceReplacement:
          row['can_request_device_replacement'] == true,
      backendState: BackendAccessState.fromBackend(
        row['access_state'] as String,
      ),
      lastChangedAt: changed == null ? null : DateTime.parse(changed),
    );
  }

  /// The RPC's `request_type` may be `existing_device`, which is not a stored
  /// request type, so only the status is interpreted.
  static JoinRequestOutcome outcomeFromJson(Map<String, dynamic> json) =>
      JoinRequestOutcome(
        status: JoinRequestStatus.fromBackend(json['status'] as String),
        requestId: json['request_id'] as String?,
        membershipId: json['membership_id'] as String?,
      );

  static ApprovedGroup groupFromRow(Map<String, dynamic> row) => ApprovedGroup(
    id: row['id'] as String,
    name: row['name'] as String,
    subject: row['subject'] as String?,
    grade: row['grade'] as String?,
    isActive: row['is_active'] as bool? ?? true,
    inviteCode: row['invite_code'] as String?,
  );

  /// Device payload for both access RPCs. Only a random installation ID and
  /// display information are sent; the backend hashes the installation ID.
  static Map<String, dynamic> devicePayload({
    required String installationId,
    required DeviceDisplayInfo device,
  }) => {
    'p_installation_id': installationId,
    'p_device_name': device.name,
    'p_platform': device.platform.backendValue,
    'p_app_version': device.appVersion,
  };
}
