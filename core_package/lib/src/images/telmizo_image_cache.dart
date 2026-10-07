import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';

/// The single on-disk image cache shared by both applications.
final telmizoImageCacheManager = CacheManager(
  Config(
    'telmizo_images',
    stalePeriod: const Duration(days: 365),
    maxNrOfCacheObjects: 500,
  ),
);

/// Where an image comes from. The [cacheKey] is stable across sessions, so a
/// private object with a fresh signed URL still hits the cache.
@immutable
sealed class TelmizoImageSource {
  const TelmizoImageSource();

  String get cacheKey;
}

/// A public HTTPS image, cached by its URL.
final class NetworkImageSource extends TelmizoImageSource {
  const NetworkImageSource(this.url);

  final String url;

  @override
  String get cacheKey => url;

  @override
  bool operator ==(Object other) =>
      other is NetworkImageSource && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// A private Supabase Storage object. Change [revision] when the object is
/// replaced at the same path so the new version is downloaded.
final class StorageImageSource extends TelmizoImageSource {
  const StorageImageSource({
    required this.bucket,
    required this.path,
    this.revision,
    this.accept,
  });

  final String bucket;
  final String path;
  final String? revision;

  /// Rejects downloaded bytes that should show the placeholder instead.
  final bool Function(Uint8List bytes)? accept;

  @override
  String get cacheKey => '$bucket/$path@${revision ?? ''}';

  @override
  bool operator ==(Object other) =>
      other is StorageImageSource &&
      other.bucket == bucket &&
      other.path == path &&
      other.revision == revision &&
      other.accept == accept;

  @override
  int get hashCode => Object.hash(bucket, path, revision, accept);
}

final class UnusableImageException implements Exception {
  const UnusableImageException();
}

/// Turns a [TelmizoImageSource] into the URL a cached image loads.
abstract interface class TelmizoImageResolver {
  Future<String> resolve(TelmizoImageSource source);
}

/// Signs private objects only when they are not cached yet. On mobile a
/// cached object resolves to its cache key, so it loads without a network
/// call; the browser on web keeps its own cache.
final class CachingImageResolver implements TelmizoImageResolver {
  CachingImageResolver({
    required this.cacheManager,
    required this.createSignedUrl,
    this.isWeb = kIsWeb,
  });

  final BaseCacheManager cacheManager;
  final Future<String> Function(String bucket, String path) createSignedUrl;
  final bool isWeb;

  @override
  Future<String> resolve(TelmizoImageSource source) async {
    switch (source) {
      case NetworkImageSource(:final url):
        return url;
      case StorageImageSource(:final bucket, :final path, :final accept):
        if (isWeb) return createSignedUrl(bucket, path);
        final key = source.cacheKey;
        final cached = await cacheManager.getFileFromCache(key);
        final file = cached != null && cached.validTill.isAfter(DateTime.now())
            ? cached.file
            : await cacheManager.getSingleFile(
                await createSignedUrl(bucket, path),
                key: key,
              );
        if (accept != null && !accept(await file.readAsBytes())) {
          throw const UnusableImageException();
        }
        return key;
    }
  }
}

final telmizoImageCacheManagerProvider = Provider<BaseCacheManager>(
  (ref) => telmizoImageCacheManager,
);

final telmizoImageResolverProvider = Provider<TelmizoImageResolver>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CachingImageResolver(
    cacheManager: ref.watch(telmizoImageCacheManagerProvider),
    createSignedUrl: (bucket, path) =>
        client.storage.from(bucket).createSignedUrl(path, 3600),
  );
});

final telmizoImageUrlProvider = FutureProvider.autoDispose
    .family<String, TelmizoImageSource>(
      (ref, source) => ref.watch(telmizoImageResolverProvider).resolve(source),
    );
