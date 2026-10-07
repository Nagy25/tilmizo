import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tilmizo_teacher/features/resources/data/tus_signed_uploader.dart';
import 'package:tilmizo_teacher/features/resources/domain/resource_models.dart';
import 'package:tilmizo_teacher/features/resources/domain/resources_repository.dart';

import '../../helpers/fake_resources.dart';

const _reservation = UploadReservation(
  id: 'r1',
  bucket: 'group-resources',
  storagePath: 't1/g1/r1.mp4',
  signedUploadToken: 'signed-token',
  useResumableUpload: true,
);

void main() {
  final file = PickedResourceFile(
    name: 'clip.mp4',
    bytes: pickedPdf(size: 13 * mib).bytes,
    mimeType: 'video/mp4',
  );

  test('creates at the signed endpoint and patches 6 MB chunks', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.method == 'POST') {
        return http.Response('', 201, headers: {'location': '/upload/r1'});
      }
      final offset = int.parse(request.headers['Upload-Offset']!);
      return http.Response(
        '',
        204,
        headers: {'upload-offset': '${offset + request.bodyBytes.length}'},
      );
    });
    final progress = <double>[];

    await TusSignedUploader(
      httpClient: client,
      storageUrl: 'https://p.supabase.co/storage/v1/',
      headers: {'apikey': 'key', 'Content-Type': 'application/json'},
    ).upload(
      reservation: _reservation,
      file: file,
      onProgress: progress.add,
      cancel: UploadCancelSignal(),
    );

    final create = requests.first;
    expect(
      create.url.toString(),
      'https://p.supabase.co/storage/v1/upload/resumable/sign',
    );
    expect(create.headers['x-signature'], 'signed-token');
    expect(create.headers['Tus-Resumable'], '1.0.0');
    expect(create.headers['apikey'], 'key');
    expect(create.headers['Upload-Length'], '${13 * mib}');
    final metadata = {
      for (final pair in create.headers['Upload-Metadata']!.split(','))
        pair.split(' ').first: utf8.decode(base64Decode(pair.split(' ').last)),
    };
    expect(metadata, {
      'bucketName': 'group-resources',
      'objectName': 't1/g1/r1.mp4',
      'contentType': 'video/mp4',
      'cacheControl': '3600',
    });

    final patches = requests.skip(1).toList();
    expect(patches.map((r) => r.url.path), everyElement('/upload/r1'));
    expect(patches.map((r) => r.headers['Upload-Offset']), [
      '0',
      '${6 * mib}',
      '${12 * mib}',
    ]);
    expect(patches.map((r) => r.bodyBytes.length), [6 * mib, 6 * mib, mib]);
    expect(
      patches.every((r) => r.headers['x-signature'] == 'signed-token'),
      isTrue,
    );
    expect(
      patches.first.headers['Content-Type'],
      'application/offset+octet-stream',
    );
    expect(progress.last, 1);
  });

  test('resumes from the committed offset after a server error', () async {
    var failedOnce = false;
    final offsets = <String>[];
    final client = MockClient((request) async {
      switch (request.method) {
        case 'POST':
          return http.Response('', 201, headers: {'location': '/upload/r1'});
        case 'HEAD':
          return http.Response(
            '',
            200,
            headers: {'upload-offset': '${6 * mib}'},
          );
      }
      offsets.add(request.headers['Upload-Offset']!);
      if (offsets.length == 2 && !failedOnce) {
        failedOnce = true;
        return http.Response('', 503);
      }
      final offset = int.parse(request.headers['Upload-Offset']!);
      return http.Response(
        '',
        204,
        headers: {'upload-offset': '${offset + request.bodyBytes.length}'},
      );
    });

    await TusSignedUploader(
      httpClient: client,
      storageUrl: 'https://p.supabase.co/storage/v1',
      headers: const {},
    ).upload(
      reservation: _reservation,
      file: file,
      onProgress: (_) {},
      cancel: UploadCancelSignal(),
    );

    expect(offsets, ['0', '${6 * mib}', '${6 * mib}', '${12 * mib}']);
  });

  test('stops between chunks when cancelled', () async {
    final cancel = UploadCancelSignal();
    var patches = 0;
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response('', 201, headers: {'location': '/upload/r1'});
      }
      patches++;
      cancel.cancel();
      final offset = int.parse(request.headers['Upload-Offset']!);
      return http.Response(
        '',
        204,
        headers: {'upload-offset': '${offset + request.bodyBytes.length}'},
      );
    });

    await expectLater(
      TusSignedUploader(
        httpClient: client,
        storageUrl: 'https://p.supabase.co/storage/v1',
        headers: const {},
      ).upload(
        reservation: _reservation,
        file: file,
        onProgress: (_) {},
        cancel: cancel,
      ),
      throwsA(isA<UploadCancelled>()),
    );
    expect(patches, 1);
  });

  test('a rejected signature is not retried', () async {
    final client = MockClient((request) async => http.Response('', 403));

    await expectLater(
      TusSignedUploader(
        httpClient: client,
        storageUrl: 'https://p.supabase.co/storage/v1',
        headers: const {},
      ).upload(
        reservation: _reservation,
        file: file,
        onProgress: (_) {},
        cancel: UploadCancelSignal(),
      ),
      throwsA(
        isA<TusUploadException>().having((e) => e.statusCode, 'status', 403),
      ),
    );
  });
}
