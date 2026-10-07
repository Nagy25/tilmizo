import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../domain/resource_models.dart';
import '../domain/resources_repository.dart';

/// Signed-token TUS 1.0.0 upload to Supabase Storage.
///
/// Creates the upload at `/upload/resumable/sign` with the reservation token
/// in `x-signature`, then PATCHes 6 MB chunks (the size Supabase requires).
/// After a transient failure it asks the server for the committed offset
/// with HEAD and resumes from there.
final class TusSignedUploader {
  TusSignedUploader({
    required http.Client httpClient,
    required String storageUrl,
    required Map<String, String> headers,
    this.maxRetries = 3,
  }) : _http = httpClient,
       _storageUrl = storageUrl.endsWith('/')
           ? storageUrl.substring(0, storageUrl.length - 1)
           : storageUrl,
       _baseHeaders = {
         for (final MapEntry(:key, :value) in headers.entries)
           if (key.toLowerCase() != 'content-type') key: value,
       };

  static const chunkSize = 6 * 1024 * 1024;

  final http.Client _http;
  final String _storageUrl;
  final Map<String, String> _baseHeaders;
  final int maxRetries;

  Future<void> upload({
    required UploadReservation reservation,
    required PickedResourceFile file,
    required void Function(double progress) onProgress,
    required UploadCancelSignal cancel,
  }) async {
    final headers = {
      ..._baseHeaders,
      'Tus-Resumable': '1.0.0',
      'x-signature': reservation.signedUploadToken,
    };
    final location = await _create(reservation, file, headers);
    final total = file.size;
    var offset = 0;
    var failures = 0;
    onProgress(0);
    while (offset < total) {
      if (cancel.isCancelled) throw const UploadCancelled();
      final end = math.min(offset + chunkSize, total);
      try {
        offset = await _patch(
          location,
          headers,
          offset,
          file.bytes.sublist(offset, end),
        );
        failures = 0;
        onProgress(offset / total);
      } on TusUploadException catch (error) {
        if (!error.retryable || ++failures > maxRetries) rethrow;
        offset = await _committedOffset(location, headers);
      } on http.ClientException {
        if (++failures > maxRetries) rethrow;
        offset = await _committedOffset(location, headers);
      }
    }
  }

  Future<Uri> _create(
    UploadReservation reservation,
    PickedResourceFile file,
    Map<String, String> headers,
  ) async {
    final endpoint = Uri.parse('$_storageUrl/upload/resumable/sign');
    final response = await _http.post(
      endpoint,
      headers: {
        ...headers,
        'Upload-Length': '${file.size}',
        'Upload-Metadata': encodeTusMetadata({
          'bucketName': reservation.bucket,
          'objectName': reservation.storagePath,
          'contentType': file.mimeType,
          'cacheControl': '3600',
        }),
      },
    );
    final location = response.headers['location'];
    if (response.statusCode != 201 || location == null) {
      throw TusUploadException(response.statusCode);
    }
    return endpoint.resolve(location);
  }

  Future<int> _patch(
    Uri location,
    Map<String, String> headers,
    int offset,
    List<int> chunk,
  ) async {
    final response = await _http.patch(
      location,
      headers: {
        ...headers,
        'Upload-Offset': '$offset',
        'Content-Type': 'application/offset+octet-stream',
      },
      body: chunk,
    );
    final next = int.tryParse(response.headers['upload-offset'] ?? '');
    if (response.statusCode != 204 || next == null) {
      throw TusUploadException(response.statusCode);
    }
    return next;
  }

  Future<int> _committedOffset(
    Uri location,
    Map<String, String> headers,
  ) async {
    final response = await _http.head(location, headers: headers);
    final offset = int.tryParse(response.headers['upload-offset'] ?? '');
    if (response.statusCode != 200 || offset == null) {
      throw TusUploadException(response.statusCode);
    }
    return offset;
  }
}

/// A non-success TUS response. 409 (offset mismatch), 423 (locked) and 5xx
/// can be resumed after reading the committed offset.
final class TusUploadException implements Exception {
  const TusUploadException(this.statusCode);

  final int statusCode;

  bool get retryable =>
      statusCode == 409 || statusCode == 423 || statusCode >= 500;

  @override
  String toString() => 'TusUploadException($statusCode)';
}

/// TUS `Upload-Metadata`: comma-separated `key base64(value)` pairs.
String encodeTusMetadata(Map<String, String> values) => values.entries
    .map((entry) => '${entry.key} ${base64Encode(utf8.encode(entry.value))}')
    .join(',');
