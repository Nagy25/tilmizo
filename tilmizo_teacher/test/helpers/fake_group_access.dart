import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:tilmizo_teacher/features/group_access/domain/access_decision_result.dart';
import 'package:tilmizo_teacher/features/group_access/domain/group_access_repository.dart';
import 'package:tilmizo_teacher/features/group_access/domain/group_member.dart';
import 'package:tilmizo_teacher/features/group_access/domain/student_device.dart';
import 'package:tilmizo_teacher/features/group_access/domain/student_join_request.dart';

import 'fakes.dart';

const studentPhone = '+201100000000';

StudentJoinRequest buildRequest({
  String id = 'request-1',
  String groupId = 'group-1',
  String? name = 'عمر خالد',
  JoinRequestType type = JoinRequestType.join,
  JoinRequestStatus status = JoinRequestStatus.pending,
  String deviceName = 'Samsung Galaxy A54',
  DevicePlatform platform = DevicePlatform.android,
}) => StudentJoinRequest(
  id: id,
  groupId: groupId,
  studentName: name,
  studentPhone: studentPhone,
  device: StudentDevice(name: deviceName, platform: platform),
  type: type,
  status: status,
  createdAt: testTime,
);

GroupMember buildMember({
  String id = 'membership-1',
  String groupId = 'group-1',
  String? name = 'عمر خالد',
  MembershipStatus status = MembershipStatus.active,
}) => GroupMember(
  membershipId: id,
  groupId: groupId,
  studentName: name,
  studentPhone: studentPhone,
  status: status,
  approvedDevice: status == MembershipStatus.active
      ? const StudentDevice(
          name: 'Samsung Galaxy A54',
          platform: DevicePlatform.android,
        )
      : null,
  joinedAt: testTime,
  updatedAt: testTime,
);

/// In-memory [GroupAccessRepository] with a controllable change stream.
final class FakeGroupAccessRepository implements GroupAccessRepository {
  FakeGroupAccessRepository({
    List<StudentJoinRequest>? requests,
    List<GroupMember>? members,
  }) : requests = [...?requests],
       members = [...?members];

  final List<StudentJoinRequest> requests;
  final List<GroupMember> members;
  final changes = StreamController<void>.broadcast();
  final decisions = <({String requestId, bool approve})>[];
  final suspensions = <String>[];
  AppFailure? fetchFailure;
  AppFailure? mutationFailure;
  Completer<void>? pendingMutation;
  int requestFetches = 0;
  int memberFetches = 0;
  int watchers = 0;

  @override
  Future<List<StudentJoinRequest>> fetchPendingRequests(String groupId) async {
    requestFetches++;
    if (fetchFailure case final failure?) throw failure;
    return requests
        .where(
          (r) => r.groupId == groupId && r.status == JoinRequestStatus.pending,
        )
        .toList();
  }

  @override
  Future<StudentJoinRequest> fetchRequest(String requestId) async {
    if (fetchFailure case final failure?) throw failure;
    return requests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => throw const AppFailure(AppFailureType.notFound),
    );
  }

  @override
  Future<List<GroupMember>> fetchMembers(String groupId) async {
    memberFetches++;
    if (fetchFailure case final failure?) throw failure;
    return members.where((m) => m.groupId == groupId).toList();
  }

  @override
  Future<GroupMember> fetchMember(String membershipId) async {
    if (fetchFailure case final failure?) throw failure;
    return members.firstWhere(
      (m) => m.membershipId == membershipId,
      orElse: () => throw const AppFailure(AppFailureType.notFound),
    );
  }

  @override
  Future<AccessDecisionResult> decide(
    String requestId, {
    required bool approve,
  }) async {
    decisions.add((requestId: requestId, approve: approve));
    await pendingMutation?.future;
    if (mutationFailure case final failure?) throw failure;
    final index = requests.indexWhere((r) => r.id == requestId);
    final request = requests[index];
    requests[index] = buildRequest(
      id: request.id,
      groupId: request.groupId,
      name: request.studentName,
      type: request.type,
      status: approve ? JoinRequestStatus.approved : JoinRequestStatus.rejected,
    );
    return AccessDecisionResult(
      status: approve ? JoinRequestStatus.approved : JoinRequestStatus.rejected,
      replacedPreviousDevice: approve && request.isReplacement,
    );
  }

  @override
  Future<void> suspend(String membershipId) async {
    suspensions.add(membershipId);
    await pendingMutation?.future;
    if (mutationFailure case final failure?) throw failure;
    final index = members.indexWhere((m) => m.membershipId == membershipId);
    members[index] = buildMember(
      id: membershipId,
      groupId: members[index].groupId,
      status: MembershipStatus.suspended,
    );
  }

  @override
  Stream<void> watchGroup(String groupId) {
    watchers++;
    return changes.stream;
  }
}
