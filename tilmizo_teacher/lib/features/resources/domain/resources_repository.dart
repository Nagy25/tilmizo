import 'package:core_package/core_package.dart';

import 'resource_models.dart';

/// Teacher access to `public.resources`. Reads go through the Data API under
/// RLS; every write goes through an RPC or Edge Function.
abstract interface class ResourcesRepository {
  /// Newest first.
  Future<ResourcesPage> fetchResources(
    String groupId, {
    int offset = 0,
    int limit = 30,
  });

  /// Null when the resource is missing or hidden by RLS.
  Future<GroupResource?> fetchResource(String resourceId);

  /// Live per-type totals for the whole group, independent of paging.
  Future<Map<ResourceType, int>> fetchTypeCounts(String groupId);

  Future<List<ResourceSessionOption>> fetchSessions(String groupId);

  Future<GroupResource> createLink({
    required String groupId,
    required ResourceType type,
    required String url,
    required ResourceDetails details,
  });

  /// Replaces title, description and session; [url] is required for link
  /// types and must be null for uploads, whose content is immutable.
  Future<GroupResource> updateMetadata({
    required String resourceId,
    required ResourceDetails details,
    String? url,
  });

  Future<UploadReservation> reserveUpload({
    required String groupId,
    required ResourceType type,
    required PickedResourceFile file,
    required ResourceDetails details,
  });

  Future<GroupResource> finalizeUpload(String reservationId);

  Future<void> cancelUpload(String reservationId);

  Future<ResourceDeletion> deleteResource(String resourceId);
}

/// Uploads reserved content with the signed token only.
abstract interface class ResourceContentUploader {
  Future<void> upload({
    required UploadReservation reservation,
    required PickedResourceFile file,
    required void Function(double progress) onProgress,
    required UploadCancelSignal cancel,
  });
}

/// Lets the user abandon an upload between chunks.
final class UploadCancelSignal {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// Thrown by uploaders when [UploadCancelSignal.cancel] was called.
final class UploadCancelled implements Exception {
  const UploadCancelled();
}
