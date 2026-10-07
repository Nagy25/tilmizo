import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_providers.dart';
import '../errors/network_errors.dart';
import '../images/telmizo_image_cache.dart';
import 'group_resource.dart';
import 'resource_file_service_io.dart'
    if (dart.library.js_interop) 'resource_file_service_web.dart'
    as platform;
import 'resource_validation.dart';
import 'resource_values.dart';

enum ResourceFileFailureType {
  /// RLS hid the object: access was revoked or the resource was deleted.
  denied,
  sessionExpired,
  network,
  invalidLink,

  /// No application on the device can open the file or link.
  cannotOpen,
  cancelled,
  unknown,
}

final class ResourceFileFailure implements Exception {
  const ResourceFileFailure(this.type);

  final ResourceFileFailureType type;

  @override
  String toString() => 'ResourceFileFailure(${type.name})';
}

/// Cancels an in-flight download started by [ResourceFileService.open].
final class ResourceDownloadCancel {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// Opens resources without public or stored signed URLs.
///
/// Uploaded files are read once through the authenticated Storage API with
/// the current session, so RLS is checked on the first open. On mobile the
/// bytes are cached in the application directory per resource version and
/// later opens use that copy without a download; on web a short-lived signed
/// URL is opened immediately and never stored.
abstract interface class ResourceFileService {
  Future<void> open(
    GroupResource resource, {
    void Function(double progress)? onProgress,
    ResourceDownloadCancel? cancel,
  });

  /// Whether this version of [resource] can open without a download.
  Future<bool> isCached(GroupResource resource);

  /// Deletes every cached version of one resource, for example after it is
  /// deleted.
  Future<void> evict(String resourceId);

  /// Deletes cached files and images, for example after access is revoked
  /// or on sign-out.
  Future<void> clearCache();
}

/// Platform hooks, injectable for tests.
final class ResourceFilePlatform {
  const ResourceFilePlatform({
    required this.downloadStream,
    required this.createShortLivedUrl,
    required this.launch,
    required this.cacheDirectoryPath,
    required this.openFile,
    this.clearImageCache = _noImageCache,
  });

  final Stream<List<int>> Function(String storagePath) downloadStream;
  final Future<String> Function(String storagePath) createShortLivedUrl;
  final Future<bool> Function(Uri uri) launch;

  /// Mobile only: the application directory that holds cached files.
  final Future<String> Function() cacheDirectoryPath;

  /// Mobile only: opens a local file in a viewer; false when none can.
  final Future<bool> Function(String filePath) openFile;

  /// Empties the shared image cache together with the file cache.
  final Future<void> Function() clearImageCache;

  static Future<void> _noImageCache() async {}
}

final class SupabaseResourceFileService implements ResourceFileService {
  SupabaseResourceFileService(this._platform);

  factory SupabaseResourceFileService.fromClient(SupabaseClient client) {
    final bucket = client.storage.from(groupResourcesBucket);
    return SupabaseResourceFileService(
      ResourceFilePlatform(
        downloadStream: bucket.downloadStream,
        createShortLivedUrl: (path) => bucket.createSignedUrl(path, 60),
        launch: (uri) => launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        ),
        cacheDirectoryPath: platform.cacheDirectoryPath,
        openFile: platform.openLocalFile,
        clearImageCache: telmizoImageCacheManager.emptyCache,
      ),
    );
  }

  final ResourceFilePlatform _platform;

  @override
  Future<void> open(
    GroupResource resource, {
    void Function(double progress)? onProgress,
    ResourceDownloadCancel? cancel,
  }) async {
    try {
      if (resource.type.isLink) {
        await _launch(resource.externalUrl);
        return;
      }
      final path = resource.storagePath;
      if (path == null) {
        throw const ResourceFileFailure(ResourceFileFailureType.denied);
      }
      await platform.openUploadedResource(
        platform: _platform,
        resource: resource,
        storagePath: path,
        onProgress: onProgress,
        cancel: cancel,
      );
    } catch (error) {
      throw mapResourceFileError(error);
    }
  }

  @override
  Future<bool> isCached(GroupResource resource) =>
      platform.isResourceCached(_platform, resource);

  @override
  Future<void> evict(String resourceId) =>
      platform.evictResource(_platform, resourceId);

  @override
  Future<void> clearCache() async {
    await platform.clearResourceCache(_platform);
    await _platform.clearImageCache();
  }

  Future<void> _launch(String? url) async {
    if (!isValidHttpsUrl(url)) {
      throw const ResourceFileFailure(ResourceFileFailureType.invalidLink);
    }
    if (!await _platform.launch(Uri.parse(url!))) {
      throw const ResourceFileFailure(ResourceFileFailureType.cannotOpen);
    }
  }
}

/// Maps Storage, auth and connectivity errors to a [ResourceFileFailure].
ResourceFileFailure mapResourceFileError(Object error) {
  if (error is ResourceFileFailure) return error;
  if (isNetworkError(error)) {
    return const ResourceFileFailure(ResourceFileFailureType.network);
  }
  if (error is AuthException) {
    return const ResourceFileFailure(ResourceFileFailureType.sessionExpired);
  }
  if (error is StorageException) {
    return switch (error.statusCode) {
      '401' => const ResourceFileFailure(
        ResourceFileFailureType.sessionExpired,
      ),
      '400' ||
      '403' ||
      '404' => const ResourceFileFailure(ResourceFileFailureType.denied),
      _ => const ResourceFileFailure(ResourceFileFailureType.unknown),
    };
  }
  return const ResourceFileFailure(ResourceFileFailureType.unknown);
}

final resourceFileServiceProvider = Provider<ResourceFileService>(
  (ref) =>
      SupabaseResourceFileService.fromClient(ref.watch(supabaseClientProvider)),
);
