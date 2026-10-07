import 'package:core_package/core_package.dart';

/// Read-only resources of a group. RLS returns rows only while this signed-in
/// session is the approved one for the group.
abstract interface class StudentResourcesRepository {
  /// Newest first.
  Future<ResourcesPage> fetchResources(
    String groupId, {
    int offset = 0,
    int limit = 30,
  });

  /// Live per-type totals for the group, independent of paging.
  Future<Map<ResourceType, int>> fetchTypeCounts(String groupId);

  /// Sessions used to label linked resources.
  Future<List<ResourceSessionOption>> fetchSessions(String groupId);
}
