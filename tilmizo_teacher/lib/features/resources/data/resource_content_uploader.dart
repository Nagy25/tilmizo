import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/resource_models.dart';
import '../domain/resources_repository.dart';
import 'tus_signed_uploader.dart';

/// Uploads with the reservation's signed token: one request for small files,
/// signed-token TUS in 6 MB chunks when the backend asks for resumable upload.
/// Ordinary bucket permissions are never used.
final class SupabaseResourceContentUploader implements ResourceContentUploader {
  SupabaseResourceContentUploader(this._client, this._httpClient);

  final SupabaseClient _client;
  final http.Client _httpClient;

  @override
  Future<void> upload({
    required UploadReservation reservation,
    required PickedResourceFile file,
    required void Function(double progress) onProgress,
    required UploadCancelSignal cancel,
  }) async {
    if (reservation.useResumableUpload) {
      await TusSignedUploader(
        httpClient: _httpClient,
        storageUrl: _client.storage.url,
        headers: _client.storage.headers,
      ).upload(
        reservation: reservation,
        file: file,
        onProgress: onProgress,
        cancel: cancel,
      );
      return;
    }
    onProgress(0);
    await _client.storage
        .from(reservation.bucket)
        .uploadBinaryToSignedUrl(
          reservation.storagePath,
          reservation.signedUploadToken,
          file.bytes,
          FileOptions(contentType: file.mimeType),
        );
    if (cancel.isCancelled) throw const UploadCancelled();
    onProgress(1);
  }
}
