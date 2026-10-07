import 'dart:async';
import 'dart:typed_data';

import 'package:core_package/core_package.dart';
import 'package:tilmizo_teacher/features/profile/domain/resource_storage_usage_repository.dart';
import 'package:tilmizo_teacher/features/profile/domain/teacher_resource_storage_usage.dart';
import 'package:tilmizo_teacher/features/resources/data/resource_file_picker.dart';
import 'package:tilmizo_teacher/features/resources/domain/resource_models.dart';
import 'package:tilmizo_teacher/features/resources/domain/resources_repository.dart';

import 'fakes.dart';

const mib = 1024 * 1024;

GroupResource buildResource({
  String id = 'resource-1',
  String groupId = 'group-1',
  String title = 'مذكرة القوانين',
  String? description,
  ResourceType type = ResourceType.pdf,
  String? sessionId,
  int? fileSize = 4 * mib,
  String? externalUrl,
  DateTime? createdAt,
}) => GroupResource(
  id: id,
  groupId: groupId,
  teacherId: testUserId,
  sessionId: sessionId,
  title: title,
  description: description,
  type: type,
  storagePath: type.isUpload ? '$testUserId/$groupId/$id.pdf' : null,
  fileName: type.isUpload ? '$id.pdf' : null,
  fileSize: type.isUpload ? fileSize : null,
  mimeType: type.isUpload ? 'application/pdf' : null,
  externalUrl: type.isLink ? externalUrl ?? 'https://example.com/$id' : null,
  createdAt: createdAt ?? testTime,
  updatedAt: createdAt ?? testTime,
);

const testUsage = TeacherResourceStorageUsage(
  planKey: 'default',
  quotaBytes: 1024 * mib,
  committedBytes: 100 * mib,
  reservedBytes: 0,
  usedBytes: 100 * mib,
  remainingBytes: 924 * mib,
  usagePercent: 9.77,
  pdfFileMaxBytes: 25 * mib,
  imageMaxBytes: 10 * mib,
  videoMaxBytes: 50 * mib,
);

final class FakeUsageRepository implements ResourceStorageUsageRepository {
  TeacherResourceStorageUsage usage = testUsage;
  int fetches = 0;

  @override
  Future<TeacherResourceStorageUsage> fetchOwnUsage() async {
    fetches++;
    return usage;
  }
}

/// In-memory [ResourcesRepository] that records every write.
final class FakeResourcesRepository implements ResourcesRepository {
  FakeResourcesRepository([List<GroupResource>? resources])
    : resources = [...?resources];

  final List<GroupResource> resources;
  final sessions = <ResourceSessionOption>[];
  final calls = <String>[];
  Object? fetchFailure;
  Object? writeFailure;
  Object? finalizeFailure;
  bool deleteCleanupPending = false;
  bool resumable = false;
  Map<String, Object?>? lastUpdate;
  int _nextId = 100;

  @override
  Future<ResourcesPage> fetchResources(
    String groupId, {
    int offset = 0,
    int limit = 30,
  }) async {
    if (fetchFailure case final failure?) throw failure;
    final all = resources.where((r) => r.groupId == groupId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = all.skip(offset).take(limit).toList();
    return ResourcesPage(resources: page, hasMore: page.length == limit);
  }

  @override
  Future<GroupResource?> fetchResource(String resourceId) async {
    if (fetchFailure case final failure?) throw failure;
    return resources.where((r) => r.id == resourceId).firstOrNull;
  }

  @override
  Future<Map<ResourceType, int>> fetchTypeCounts(String groupId) async {
    if (fetchFailure case final failure?) throw failure;
    final counts = <ResourceType, int>{};
    for (final resource in resources.where((r) => r.groupId == groupId)) {
      counts[resource.type] = (counts[resource.type] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<List<ResourceSessionOption>> fetchSessions(String groupId) async =>
      sessions;

  @override
  Future<GroupResource> createLink({
    required String groupId,
    required ResourceType type,
    required String url,
    required ResourceDetails details,
  }) async {
    calls.add('createLink');
    if (writeFailure case final failure?) throw failure;
    final resource = buildResource(
      id: 'resource-${_nextId++}',
      groupId: groupId,
      title: details.title,
      description: details.description,
      sessionId: details.sessionId,
      type: type,
      externalUrl: url,
      createdAt: testTime.add(const Duration(days: 1)),
    );
    resources.add(resource);
    return resource;
  }

  @override
  Future<GroupResource> updateMetadata({
    required String resourceId,
    required ResourceDetails details,
    String? url,
  }) async {
    calls.add('update');
    lastUpdate = {
      'title': details.title,
      'description': details.description,
      'session_id': details.sessionId,
      'url': url,
    };
    if (writeFailure case final failure?) throw failure;
    final index = resources.indexWhere((r) => r.id == resourceId);
    final old = resources[index];
    final updated = buildResource(
      id: old.id,
      groupId: old.groupId,
      title: details.title,
      description: details.description,
      sessionId: details.sessionId,
      type: old.type,
      externalUrl: url,
      createdAt: old.createdAt,
    );
    resources[index] = updated;
    return updated;
  }

  @override
  Future<UploadReservation> reserveUpload({
    required String groupId,
    required ResourceType type,
    required PickedResourceFile file,
    required ResourceDetails details,
  }) async {
    calls.add('reserve');
    if (writeFailure case final failure?) throw failure;
    final id = 'resource-${_nextId++}';
    _pending[id] = buildResource(
      id: id,
      groupId: groupId,
      title: details.title,
      description: details.description,
      sessionId: details.sessionId,
      type: type,
      fileSize: file.size,
      createdAt: testTime.add(const Duration(days: 1)),
    );
    return UploadReservation(
      id: id,
      bucket: groupResourcesBucket,
      storagePath: '$testUserId/$groupId/$id.pdf',
      signedUploadToken: 'token-$id',
      useResumableUpload: resumable,
    );
  }

  final _pending = <String, GroupResource>{};

  @override
  Future<GroupResource> finalizeUpload(String reservationId) async {
    calls.add('finalize');
    if (finalizeFailure case final failure?) {
      finalizeFailure = null;
      throw failure;
    }
    final resource = _pending.remove(reservationId)!;
    resources.add(resource);
    return resource;
  }

  @override
  Future<void> cancelUpload(String reservationId) async {
    calls.add('cancel');
    _pending.remove(reservationId);
  }

  @override
  Future<ResourceDeletion> deleteResource(String resourceId) async {
    calls.add('delete');
    if (writeFailure case final failure?) throw failure;
    resources.removeWhere((r) => r.id == resourceId);
    return ResourceDeletion(cleanupPending: deleteCleanupPending);
  }
}

/// Uploader that reports progress and can fail or wait.
final class FakeContentUploader implements ResourceContentUploader {
  Object? failure;
  Completer<void>? gate;
  final uploaded = <String>[];

  @override
  Future<void> upload({
    required UploadReservation reservation,
    required PickedResourceFile file,
    required void Function(double progress) onProgress,
    required UploadCancelSignal cancel,
  }) async {
    onProgress(0.5);
    if (gate case final gate?) await gate.future;
    if (cancel.isCancelled) throw const UploadCancelled();
    if (failure case final failure?) throw failure;
    uploaded.add(reservation.storagePath);
    onProgress(1);
  }
}

final class FakeFilePicker implements ResourceFilePicker {
  PickedResourceFile? next;

  @override
  Future<PickedResourceFile?> pick(ResourceType type) async => next;
}

PickedResourceFile pickedPdf({int size = 1024, String name = 'notes.pdf'}) =>
    PickedResourceFile(
      name: name,
      bytes: Uint8List(size),
      mimeType: mimeTypeForFileName(name),
    );

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
