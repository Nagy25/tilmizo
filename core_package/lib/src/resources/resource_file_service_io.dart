import 'dart:async';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'group_resource.dart';
import 'resource_file_service.dart';

const _cacheFolder = 'telmizo_resources';

Future<String> cacheDirectoryPath() async =>
    (await getApplicationSupportDirectory()).path;

Future<bool> openLocalFile(String filePath) async =>
    (await OpenFilex.open(filePath)).type == ResultType.done;

/// Opens the cached copy when present; otherwise streams the object into the
/// application cache first. A new `updated_at` is a new version, so an edited
/// file is downloaded again and the previous version is removed.
Future<void> openUploadedResource({
  required ResourceFilePlatform platform,
  required GroupResource resource,
  required String storagePath,
  void Function(double progress)? onProgress,
  ResourceDownloadCancel? cancel,
}) async {
  final file = await _cachedFile(platform, resource);
  if (!await _isComplete(file, resource)) {
    await _download(
      platform: platform,
      resource: resource,
      storagePath: storagePath,
      target: file,
      onProgress: onProgress,
      cancel: cancel,
    );
  }
  onProgress?.call(1);
  if (!await platform.openFile(file.path)) {
    throw const ResourceFileFailure(ResourceFileFailureType.cannotOpen);
  }
}

Future<bool> isResourceCached(
  ResourceFilePlatform platform,
  GroupResource resource,
) async =>
    resource.type.isUpload &&
    resource.storagePath != null &&
    await _isComplete(await _cachedFile(platform, resource), resource);

Future<void> evictResource(
  ResourceFilePlatform platform,
  String resourceId,
) async {
  final folder = await _resourceFolder(platform, resourceId);
  if (await folder.exists()) await folder.delete(recursive: true);
}

Future<void> clearResourceCache(ResourceFilePlatform platform) async {
  final folder = Directory(
    '${await platform.cacheDirectoryPath()}/$_cacheFolder',
  );
  if (await folder.exists()) await folder.delete(recursive: true);
}

Future<void> _download({
  required ResourceFilePlatform platform,
  required GroupResource resource,
  required String storagePath,
  required File target,
  void Function(double progress)? onProgress,
  ResourceDownloadCancel? cancel,
}) async {
  // Drops any older version before writing the new one.
  await evictResource(platform, resource.id);
  await target.parent.create(recursive: true);
  final partial = File('${target.path}.part');

  final sink = partial.openWrite();
  final total = resource.fileSize ?? 0;
  var received = 0;
  final done = Completer<void>();
  late final StreamSubscription<List<int>> subscription;
  subscription = platform
      .downloadStream(storagePath)
      .listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress?.call((received / total).clamp(0, 1));
        },
        onError: (Object error) {
          if (!done.isCompleted) done.completeError(error);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );
  unawaited(
    cancel?.whenCancelled.then((_) {
      if (done.isCompleted) return;
      unawaited(subscription.cancel());
      done.completeError(
        const ResourceFileFailure(ResourceFileFailureType.cancelled),
      );
    }),
  );

  try {
    await done.future;
    await sink.close();
  } catch (_) {
    await sink.close();
    await evictResource(platform, resource.id);
    rethrow;
  }
  // Only a fully written file gets its final name, so a partial download is
  // never mistaken for a cached copy.
  await partial.rename(target.path);
}

Future<bool> _isComplete(File file, GroupResource resource) async {
  if (!await file.exists()) return false;
  final expected = resource.fileSize;
  return expected == null || await file.length() == expected;
}

Future<Directory> _resourceFolder(
  ResourceFilePlatform platform,
  String resourceId,
) async => Directory(
  '${await platform.cacheDirectoryPath()}/$_cacheFolder/$resourceId',
);

Future<File> _cachedFile(
  ResourceFilePlatform platform,
  GroupResource resource,
) async {
  final folder = await _resourceFolder(platform, resource.id);
  final version = resource.updatedAt.millisecondsSinceEpoch;
  return File('${folder.path}/$version/${_safeFileName(resource)}');
}

String _safeFileName(GroupResource resource) {
  final name = (resource.fileName ?? resource.id).replaceAll(
    RegExp(r'[/\\:*?"<>|\x00-\x1f]'),
    '_',
  );
  return name.isEmpty ? resource.id : name;
}
