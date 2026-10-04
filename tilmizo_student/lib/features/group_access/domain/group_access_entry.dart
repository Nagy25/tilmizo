import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

import 'backend_access_state.dart';
import 'student_access_state.dart';

/// One group's access summary from `get_my_group_access_overview`. Contains
/// only safe display and status fields: no invite codes, installation
/// hashes, or session IDs.
@immutable
final class GroupAccessEntry {
  const GroupAccessEntry({
    required this.groupId,
    required this.groupName,
    required this.backendState,
    required this.requestFromCurrentSession,
    required this.currentSessionApproved,
    required this.canRequestDeviceReplacement,
    this.subject,
    this.grade,
    this.teacherName,
    this.membershipId,
    this.membershipStatus,
    this.approvedDeviceName,
    this.latestRequestId,
    this.requestStatus,
    this.requestType,
    this.lastChangedAt,
    this.previouslyApprovedHere = false,
  });

  final String groupId;
  final String groupName;
  final String? subject;
  final String? grade;
  final String? teacherName;
  final String? membershipId;
  final MembershipStatus? membershipStatus;
  final String? approvedDeviceName;
  final String? latestRequestId;
  final JoinRequestStatus? requestStatus;
  final JoinRequestType? requestType;
  final bool requestFromCurrentSession;
  final bool currentSessionApproved;
  final bool canRequestDeviceReplacement;
  final BackendAccessState backendState;
  final DateTime? lastChangedAt;

  /// Display hint only: this installation saw the group approved before.
  /// It distinguishes "replaced" from "new device" wording and never grants
  /// access; the backend state remains the authority.
  final bool previouslyApprovedHere;

  StudentAccessState get state => deriveAccessState(this);

  /// A replacement this session asked for was rejected by the teacher.
  bool get replacementRejected =>
      requestType == JoinRequestType.deviceReplacement &&
      requestStatus == JoinRequestStatus.rejected &&
      requestFromCurrentSession;

  GroupAccessEntry withPreviouslyApprovedHere(bool value) => GroupAccessEntry(
    groupId: groupId,
    groupName: groupName,
    backendState: backendState,
    requestFromCurrentSession: requestFromCurrentSession,
    currentSessionApproved: currentSessionApproved,
    canRequestDeviceReplacement: canRequestDeviceReplacement,
    subject: subject,
    grade: grade,
    teacherName: teacherName,
    membershipId: membershipId,
    membershipStatus: membershipStatus,
    approvedDeviceName: approvedDeviceName,
    latestRequestId: latestRequestId,
    requestStatus: requestStatus,
    requestType: requestType,
    lastChangedAt: lastChangedAt,
    previouslyApprovedHere: value,
  );

  @override
  bool operator ==(Object other) =>
      other is GroupAccessEntry &&
      other.groupId == groupId &&
      other.groupName == groupName &&
      other.subject == subject &&
      other.grade == grade &&
      other.teacherName == teacherName &&
      other.membershipId == membershipId &&
      other.membershipStatus == membershipStatus &&
      other.approvedDeviceName == approvedDeviceName &&
      other.latestRequestId == latestRequestId &&
      other.requestStatus == requestStatus &&
      other.requestType == requestType &&
      other.requestFromCurrentSession == requestFromCurrentSession &&
      other.currentSessionApproved == currentSessionApproved &&
      other.canRequestDeviceReplacement == canRequestDeviceReplacement &&
      other.backendState == backendState &&
      other.lastChangedAt == lastChangedAt &&
      other.previouslyApprovedHere == previouslyApprovedHere;

  @override
  int get hashCode => Object.hashAll([
    groupId,
    groupName,
    subject,
    grade,
    teacherName,
    membershipId,
    membershipStatus,
    approvedDeviceName,
    latestRequestId,
    requestStatus,
    requestType,
    requestFromCurrentSession,
    currentSessionApproved,
    canRequestDeviceReplacement,
    backendState,
    lastChangedAt,
    previouslyApprovedHere,
  ]);
}

/// Maps the backend's `access_state` to the student-facing screen state.
StudentAccessState deriveAccessState(GroupAccessEntry entry) =>
    switch (entry.backendState) {
      BackendAccessState.approved => StudentAccessState.approved,
      BackendAccessState.joinPending => StudentAccessState.pendingJoin,
      BackendAccessState.deviceReplacementPending =>
        StudentAccessState.replacementPending,
      BackendAccessState.differentDevice =>
        entry.previouslyApprovedHere
            ? StudentAccessState.accessReplaced
            : StudentAccessState.newDeviceRequired,
      BackendAccessState.rejected => StudentAccessState.rejected,
      BackendAccessState.suspended ||
      BackendAccessState.removed => StudentAccessState.accessRemoved,
      // A request from another session: still pending, or otherwise ended.
      BackendAccessState.none =>
        entry.requestStatus == JoinRequestStatus.pending
            ? StudentAccessState.pendingJoin
            : StudentAccessState.rejected,
    };
