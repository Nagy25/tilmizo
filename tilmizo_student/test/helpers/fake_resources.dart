import 'package:core_package/core_package.dart';
import 'package:tilmizo_student/features/resources/domain/student_resources_repository.dart';

GroupResource buildResource({
  String id = 'resource-1',
  String groupId = 'group-1',
  String title = 'مذكرة القوانين',
  String? description,
  ResourceType type = ResourceType.pdf,
  String? sessionId,
  int fileSize = 4404019,
  String? externalUrl,
}) => GroupResource(
  id: id,
  groupId: groupId,
  teacherId: 'teacher-1',
  sessionId: sessionId,
  title: title,
  description: description,
  type: type,
  storagePath: type.isUpload ? 'teacher-1/$groupId/$id.pdf' : null,
  fileName: type.isUpload ? '$id.pdf' : null,
  fileSize: type.isUpload ? fileSize : null,
  mimeType: type.isUpload ? 'application/pdf' : null,
  externalUrl: type.isLink ? externalUrl ?? 'https://example.com/$id' : null,
  createdAt: DateTime.utc(2026, 10, 5),
  updatedAt: DateTime.utc(2026, 10, 5),
);

/// RLS-like fake: returns rows only for groups in [visibleGroups].
final class FakeStudentResourcesRepository
    implements StudentResourcesRepository {
  final resources = <GroupResource>[];
  final sessions = <ResourceSessionOption>[];
  final visibleGroups = <String>{'group-1'};
  AppFailure? failure;
  int fetches = 0;

  Iterable<GroupResource> _visible(String groupId) =>
      visibleGroups.contains(groupId)
      ? resources.where((r) => r.groupId == groupId)
      : const [];

  @override
  Future<ResourcesPage> fetchResources(
    String groupId, {
    int offset = 0,
    int limit = 30,
  }) async {
    fetches++;
    if (failure case final failure?) throw failure;
    final page = _visible(groupId).skip(offset).take(limit).toList();
    return ResourcesPage(resources: page, hasMore: page.length == limit);
  }

  @override
  Future<Map<ResourceType, int>> fetchTypeCounts(String groupId) async {
    if (failure case final failure?) throw failure;
    final counts = <ResourceType, int>{};
    for (final resource in _visible(groupId)) {
      counts[resource.type] = (counts[resource.type] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<List<ResourceSessionOption>> fetchSessions(String groupId) async =>
      sessions;
}

/// Records opens instead of downloading.
final class FakeResourceFileService implements ResourceFileService {
  final opened = <String>[];
  ResourceFileFailureType? failure;
  int clears = 0;

  @override
  Future<void> open(
    GroupResource resource, {
    void Function(double progress)? onProgress,
    ResourceDownloadCancel? cancel,
  }) async {
    onProgress?.call(0.5);
    if (failure case final failure?) throw ResourceFileFailure(failure);
    opened.add(resource.id);
  }

  @override
  Future<bool> isCached(GroupResource resource) async => false;

  @override
  Future<void> evict(String resourceId) async {}

  @override
  Future<void> clearCache() async => clears++;
}
