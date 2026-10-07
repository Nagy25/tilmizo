import 'resource_values.dart';

/// Backend column limits from `public.resources`.
const resourceTitleMaxLength = 200;
const resourceDescriptionMaxLength = 5000;
const resourceUrlMaxLength = 2048;
const resourceFileNameMaxLength = 255;

/// Whether [value] is an HTTPS URL the backend accepts and the apps may
/// launch: `^https://[^[:space:]]+$`, at most [resourceUrlMaxLength]
/// characters, with a host.
bool isValidHttpsUrl(String? value) {
  if (value == null || value.isEmpty || value.length > resourceUrlMaxLength) {
    return false;
  }
  if (!value.startsWith('https://') || value.contains(RegExp(r'\s'))) {
    return false;
  }
  final uri = Uri.tryParse(value);
  return uri != null && uri.isScheme('https') && uri.host.isNotEmpty;
}

/// Per-type upload limits returned by `get_my_resource_storage_usage()`.
final class ResourceUploadLimits {
  const ResourceUploadLimits({
    required this.pdfFileMaxBytes,
    required this.imageMaxBytes,
    required this.videoMaxBytes,
    required this.remainingBytes,
  });

  final int pdfFileMaxBytes;
  final int imageMaxBytes;
  final int videoMaxBytes;

  /// The teacher-wide quota still available, including reservations.
  final int remainingBytes;

  /// The single-file limit for [type], or `null` for link types.
  int? maxBytesFor(ResourceType type) => switch (type) {
    ResourceType.pdf || ResourceType.file => pdfFileMaxBytes,
    ResourceType.image => imageMaxBytes,
    ResourceType.uploadedVideo => videoMaxBytes,
    ResourceType.externalLink || ResourceType.videoLink => null,
  };
}

enum ResourceFileProblem {
  empty,
  nameTooLong,
  wrongFormat,
  tooLarge,
  quotaExceeded,
}

/// Quick local feedback mirroring the `resource-upload` checks. The backend
/// remains authoritative and also inspects the stored bytes.
ResourceFileProblem? validateResourceFile({
  required ResourceType type,
  required String fileName,
  required String mimeType,
  required int sizeBytes,
  required ResourceUploadLimits limits,
}) {
  assert(type.isUpload, 'Links are not uploaded');
  if (sizeBytes <= 0 || fileName.trim().isEmpty) {
    return ResourceFileProblem.empty;
  }
  if (fileName.length > resourceFileNameMaxLength) {
    return ResourceFileProblem.nameTooLong;
  }
  final name = fileName.toLowerCase();
  final formatOk = switch (type) {
    ResourceType.pdf => name.endsWith('.pdf') && mimeType == 'application/pdf',
    ResourceType.uploadedVideo =>
      name.endsWith('.mp4') && mimeType == 'video/mp4',
    ResourceType.image => mimeType.startsWith('image/'),
    _ => mimeType.isNotEmpty,
  };
  if (!formatOk) return ResourceFileProblem.wrongFormat;
  if (sizeBytes > limits.maxBytesFor(type)!) {
    return ResourceFileProblem.tooLarge;
  }
  if (sizeBytes > limits.remainingBytes) {
    return ResourceFileProblem.quotaExceeded;
  }
  return null;
}

/// A MIME type inferred from a file name, defaulting to
/// `application/octet-stream`. Uploads must send a correct content type
/// because finalize checks the stored object's metadata.
String mimeTypeForFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  return _mimeTypes[extension] ?? 'application/octet-stream';
}

const _mimeTypes = {
  'pdf': 'application/pdf',
  'mp4': 'video/mp4',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'avif': 'image/avif',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'zip': 'application/zip',
  'txt': 'text/plain',
  'csv': 'text/csv',
  'mp3': 'audio/mpeg',
  'm4a': 'audio/mp4',
};
