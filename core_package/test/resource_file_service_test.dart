import 'dart:async';
import 'dart:io';

import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

GroupResource _resource({
  ResourceType type = ResourceType.pdf,
  String? storagePath = 't1/g1/r1.pdf',
  String? externalUrl,
  DateTime? updatedAt,
}) => GroupResource(
  id: 'r1',
  groupId: 'g1',
  teacherId: 't1',
  title: 'Notes',
  type: type,
  storagePath: storagePath,
  fileName: 'notes.pdf',
  fileSize: 4,
  externalUrl: externalUrl,
  createdAt: DateTime.utc(2026),
  updatedAt: updatedAt ?? DateTime.utc(2026),
);

void main() {
  late Directory temp;
  late List<String> opened;
  late List<Uri> launched;
  late Stream<List<int>> Function(String) download;
  late int downloads;
  late int imageClears;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('resources_test');
    opened = [];
    launched = [];
    downloads = 0;
    imageClears = 0;
    download = (_) => Stream.fromIterable([
      [1, 2],
      [3, 4],
    ]);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  SupabaseResourceFileService service({bool openResult = true}) =>
      SupabaseResourceFileService(
        ResourceFilePlatform(
          downloadStream: (path) {
            downloads++;
            return download(path);
          },
          createShortLivedUrl: (path) async => 'https://signed/$path',
          launch: (uri) async {
            launched.add(uri);
            return true;
          },
          cacheDirectoryPath: () async => temp.path,
          openFile: (path) async {
            opened.add(path);
            return openResult;
          },
          clearImageCache: () async => imageClears++,
        ),
      );

  test('downloads with progress through the authenticated stream', () async {
    final progress = <double>[];
    await service().open(_resource(), onProgress: progress.add);

    expect(progress, [0.5, 1, 1]);
    expect(
      opened.single,
      endsWith('/r1/${DateTime.utc(2026).millisecondsSinceEpoch}/notes.pdf'),
    );
    expect(await File(opened.single).readAsBytes(), [1, 2, 3, 4]);
  });

  test('maps denied Storage reads and removes partial files', () async {
    download = (_) => Stream.error(
      const StorageException('Object not found', statusCode: '400'),
    );

    await expectLater(
      service().open(_resource()),
      throwsA(
        isA<ResourceFileFailure>().having(
          (failure) => failure.type,
          'type',
          ResourceFileFailureType.denied,
        ),
      ),
    );
    expect(opened, isEmpty);
    expect(
      Directory('${temp.path}/telmizo_resources/r1').existsSync(),
      isFalse,
    );
  });

  test('maps expired sessions and connectivity failures', () async {
    download = (_) =>
        Stream.error(const StorageException('Unauthorized', statusCode: '401'));
    await expectLater(
      service().open(_resource()),
      throwsA(
        isA<ResourceFileFailure>().having(
          (failure) => failure.type,
          'type',
          ResourceFileFailureType.sessionExpired,
        ),
      ),
    );

    download = (_) => Stream.error(http.ClientException('offline'));
    await expectLater(
      service().open(_resource()),
      throwsA(
        isA<ResourceFileFailure>().having(
          (failure) => failure.type,
          'type',
          ResourceFileFailureType.network,
        ),
      ),
    );
  });

  test('cancels an in-flight download', () async {
    final controller = StreamController<List<int>>();
    download = (_) => controller.stream;
    final cancel = ResourceDownloadCancel();

    final result = service().open(_resource(), cancel: cancel);
    controller.add([1]);
    await Future<void>.delayed(Duration.zero);
    cancel.cancel();

    await expectLater(
      result,
      throwsA(
        isA<ResourceFileFailure>().having(
          (failure) => failure.type,
          'type',
          ResourceFileFailureType.cancelled,
        ),
      ),
    );
    expect(opened, isEmpty);
    expect(await service().isCached(_resource()), isFalse);
    await controller.close();
  });

  test('reports when no viewer can open the file', () async {
    await expectLater(
      service(openResult: false).open(_resource()),
      throwsA(
        isA<ResourceFileFailure>().having(
          (failure) => failure.type,
          'type',
          ResourceFileFailureType.cannotOpen,
        ),
      ),
    );
  });

  test('a missing storage path is treated as denied', () async {
    await expectLater(
      service().open(_resource(storagePath: null)),
      throwsA(isA<ResourceFileFailure>()),
    );
  });

  test('launches only valid HTTPS links', () async {
    await service().open(
      _resource(
        type: ResourceType.videoLink,
        storagePath: null,
        externalUrl: 'https://youtu.be/x',
      ),
    );
    expect(launched, [Uri.parse('https://youtu.be/x')]);

    await expectLater(
      service().open(
        _resource(
          type: ResourceType.externalLink,
          storagePath: null,
          externalUrl: 'http://insecure.test',
        ),
      ),
      throwsA(
        isA<ResourceFileFailure>().having(
          (failure) => failure.type,
          'type',
          ResourceFileFailureType.invalidLink,
        ),
      ),
    );
    expect(launched, hasLength(1));
  });

  test('opens the cached copy without downloading again', () async {
    await service().open(_resource());
    expect(await service().isCached(_resource()), isTrue);

    final progress = <double>[];
    await service().open(_resource(), onProgress: progress.add);

    expect(downloads, 1);
    expect(progress, [1]);
    expect(opened, hasLength(2));
    expect(opened.last, opened.first);
  });

  test('a new version downloads again and replaces the old copy', () async {
    await service().open(_resource());
    final edited = _resource(updatedAt: DateTime.utc(2027));
    expect(await service().isCached(edited), isFalse);

    await service().open(edited);

    expect(downloads, 2);
    expect(File(opened.first).existsSync(), isFalse);
    expect(File(opened.last).existsSync(), isTrue);
  });

  test('an incomplete file is not treated as cached', () async {
    download = (_) => Stream.value([1, 2]);
    await service().open(_resource());
    expect(await service().isCached(_resource()), isFalse);
  });

  test('evicts one resource', () async {
    await service().open(_resource());
    await service().evict('r1');
    expect(await service().isCached(_resource()), isFalse);
  });

  test('clears cached files and images', () async {
    await service().open(_resource());
    await service().clearCache();
    expect(Directory('${temp.path}/telmizo_resources').existsSync(), isFalse);
    expect(imageClears, 1);
  });
}
