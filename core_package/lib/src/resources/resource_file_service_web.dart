import 'group_resource.dart';
import 'resource_file_service.dart';

Future<String> cacheDirectoryPath() async => '';

Future<bool> openLocalFile(String filePath) async => false;

/// Opens a 60-second signed URL in a new tab immediately; it is never stored.
/// The browser keeps its own HTTP cache, so nothing is cached here.
Future<void> openUploadedResource({
  required ResourceFilePlatform platform,
  required GroupResource resource,
  required String storagePath,
  void Function(double progress)? onProgress,
  ResourceDownloadCancel? cancel,
}) async {
  final url = await platform.createShortLivedUrl(storagePath);
  if (cancel?.isCancelled ?? false) {
    throw const ResourceFileFailure(ResourceFileFailureType.cancelled);
  }
  if (!await platform.launch(Uri.parse(url))) {
    throw const ResourceFileFailure(ResourceFileFailureType.cannotOpen);
  }
}

Future<bool> isResourceCached(
  ResourceFilePlatform platform,
  GroupResource resource,
) async => false;

Future<void> evictResource(
  ResourceFilePlatform platform,
  String resourceId,
) async {}

Future<void> clearResourceCache(ResourceFilePlatform platform) async {}
