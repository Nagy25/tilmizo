import 'package:auto_route/auto_route.dart';

import '../features/auth/domain/student_destination.dart';
import '../features/group_access/domain/group_access_entry.dart';
import '../features/group_access/domain/student_access_state.dart';
import 'app_router.dart';

extension StudentFlowRoutes on StudentFlowResult {
  /// The complete stack for this destination.
  List<PageRouteInfo> get routes => switch (destination) {
    StudentDestination.phoneLogin => [PhoneLoginRoute()],
    StudentDestination.completeProfile => [const CompleteProfileRoute()],
    StudentDestination.emptyGroups => [const EmptyGroupsRoute()],
    StudentDestination.groupsHome => [
      const GroupsHomeRoute(),
      if (focus case final entry?) accessStateRoute(entry),
    ],
  };
}

/// The status screen matching a group's current access state.
PageRouteInfo accessStateRoute(GroupAccessEntry entry) {
  final groupId = entry.groupId;
  return switch (entry.state) {
    StudentAccessState.pendingJoin => PendingRequestRoute(groupId: groupId),
    StudentAccessState.rejected => RequestRejectedRoute(groupId: groupId),
    StudentAccessState.approved => ApprovedGroupRoute(groupId: groupId),
    StudentAccessState.newDeviceRequired => NewDeviceRequiredRoute(
      groupId: groupId,
    ),
    StudentAccessState.replacementPending => ReplacementPendingRoute(
      groupId: groupId,
    ),
    StudentAccessState.accessReplaced => AccessReplacedRoute(groupId: groupId),
    StudentAccessState.accessRemoved => AccessRemovedRoute(groupId: groupId),
  };
}
