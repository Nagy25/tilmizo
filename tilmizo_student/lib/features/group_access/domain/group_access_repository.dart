import 'approved_group.dart';
import 'group_access_entry.dart';
import 'join_request_outcome.dart';

/// Student group access. Implementations throw only `AppFailure`. The
/// student and session always come from the authenticated JWT on the
/// backend; only the random installation ID and display info are sent.
abstract interface class GroupAccessRepository {
  /// Status of every group the student has requested or joined.
  Future<List<GroupAccessEntry>> fetchOverview();

  Future<JoinRequestOutcome> requestAccess(String inviteCode);

  /// Requests approval of this device for an existing membership, without
  /// the invite code.
  Future<JoinRequestOutcome> requestDeviceReplacement(String membershipId);

  Future<void> leaveGroup(String membershipId);

  /// Throws a not-found failure when RLS no longer allows this session.
  Future<ApprovedGroup> fetchApprovedGroup(String groupId);

  /// Emits whenever the student's requests or memberships change.
  Stream<void> watchMyAccess();
}
