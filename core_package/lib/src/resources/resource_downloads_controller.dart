import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'group_resource.dart';
import 'resource_file_service.dart';

/// Progress (0–1) of in-flight opens, keyed by resource id.
typedef ResourceDownloads = Map<String, double>;

/// Opens resources with progress and cancellation; shared by both apps.
final resourceDownloadsProvider =
    NotifierProvider.autoDispose<
      ResourceDownloadsController,
      ResourceDownloads
    >(ResourceDownloadsController.new);

class ResourceDownloadsController extends Notifier<ResourceDownloads> {
  final _cancels = <String, ResourceDownloadCancel>{};

  @override
  ResourceDownloads build() {
    ref.onDispose(() {
      for (final cancel in _cancels.values) {
        cancel.cancel();
      }
    });
    return const {};
  }

  /// Opens [resource], returning the failure, or null on success or user
  /// cancellation. [authorize] runs before a download so callers can
  /// re-check access; a cached copy opens directly without it.
  Future<ResourceFileFailureType?> open(
    GroupResource resource, {
    Future<bool> Function()? authorize,
  }) async {
    if (_cancels.containsKey(resource.id)) return null;
    final service = ref.read(resourceFileServiceProvider);
    final cancel = _cancels[resource.id] = ResourceDownloadCancel();
    try {
      final cached = await service.isCached(resource);
      if (!cached) _setProgress(resource.id, 0);
      if (!cached && authorize != null && !await authorize()) {
        return ResourceFileFailureType.denied;
      }
      await service.open(
        resource,
        cancel: cancel,
        onProgress: cached
            ? null
            : (progress) => _setProgress(resource.id, progress),
      );
      return null;
    } on ResourceFileFailure catch (failure) {
      return failure.type == ResourceFileFailureType.cancelled
          ? null
          : failure.type;
    } catch (error) {
      return mapResourceFileError(error).type;
    } finally {
      _cancels.remove(resource.id);
      if (ref.mounted) {
        state = {
          for (final entry in state.entries)
            if (entry.key != resource.id) entry.key: entry.value,
        };
      }
    }
  }

  void cancel(String resourceId) => _cancels[resourceId]?.cancel();

  /// Deletes the cached copy of one resource, for example after deletion.
  Future<void> evict(String resourceId) =>
      ref.read(resourceFileServiceProvider).evict(resourceId);

  /// Stops every download and deletes cached files, for example when the
  /// viewer's access is revoked.
  Future<void> revokeAll() async {
    for (final cancel in _cancels.values) {
      cancel.cancel();
    }
    await ref.read(resourceFileServiceProvider).clearCache();
  }

  void _setProgress(String id, double progress) {
    if (!ref.mounted || !_cancels.containsKey(id)) return;
    state = {...state, id: progress};
  }
}
