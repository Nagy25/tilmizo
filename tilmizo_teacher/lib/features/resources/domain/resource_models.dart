import 'package:flutter/foundation.dart';

/// Title, description and session shared by every resource type.
@immutable
final class ResourceDetails {
  const ResourceDetails({
    required this.title,
    this.description,
    this.sessionId,
  });

  final String title;
  final String? description;
  final String? sessionId;
}

/// A file chosen for upload, held in memory (at most the 50 MB bucket limit).
@immutable
final class PickedResourceFile {
  const PickedResourceFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;

  int get size => bytes.lengthInBytes;
}

/// A `resource-upload` reservation: a unique object path and signed token.
@immutable
final class UploadReservation {
  const UploadReservation({
    required this.id,
    required this.bucket,
    required this.storagePath,
    required this.signedUploadToken,
    required this.useResumableUpload,
  });

  final String id;
  final String bucket;
  final String storagePath;
  final String signedUploadToken;

  /// True above 6 MB: upload with signed-token TUS in 6 MB chunks.
  final bool useResumableUpload;
}

/// Outcome of `resource-delete`; the resource is gone either way.
@immutable
final class ResourceDeletion {
  const ResourceDeletion({required this.cleanupPending});

  /// The object delete was deferred (`202`); quota is released later.
  final bool cleanupPending;
}
