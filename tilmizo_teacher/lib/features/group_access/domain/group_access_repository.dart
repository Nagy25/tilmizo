import 'access_decision_result.dart';
import 'group_member.dart';
import 'student_join_request.dart';

/// Teacher access management for groups the authenticated teacher owns.
/// Implementations throw only `AppFailure`; ownership is enforced by the
/// backend from the session, never from client-supplied IDs.
abstract interface class GroupAccessRepository {
  /// Pending requests for one owned group, newest first.
  Future<List<StudentJoinRequest>> fetchPendingRequests(String groupId);

  Future<StudentJoinRequest> fetchRequest(String requestId);

  /// Active and suspended students of one owned group.
  Future<List<GroupMember>> fetchMembers(String groupId);

  Future<GroupMember> fetchMember(String membershipId);

  Future<AccessDecisionResult> decide(
    String requestId, {
    required bool approve,
  });

  /// Suspends the student's access to this group only.
  Future<void> suspend(String membershipId);

  /// Emits whenever requests or memberships of [groupId] change.
  Stream<void> watchGroup(String groupId);
}
