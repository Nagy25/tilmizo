import 'resource_values.dart';

/// One row of `public.resources`, as visible to the signed-in user under RLS.
final class GroupResource {
  const GroupResource({
    required this.id,
    required this.groupId,
    required this.teacherId,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
    this.description,
    this.storagePath,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.externalUrl,
  });

  /// Parses a Data API, RPC or Edge Function row. Throws [FormatException]
  /// when a required column is missing or the type is unknown.
  factory GroupResource.fromRow(Map<String, dynamic> row) {
    return GroupResource(
      id: _required(row, 'id'),
      groupId: _required(row, 'group_id'),
      teacherId: _required(row, 'teacher_id'),
      sessionId: row['session_id'] as String?,
      title: _required(row, 'title'),
      description: row['description'] as String?,
      type: ResourceType.fromBackend(_required(row, 'type')),
      storagePath: row['storage_path'] as String?,
      fileName: row['file_name'] as String?,
      fileSize: (row['file_size'] as num?)?.toInt(),
      mimeType: row['mime_type'] as String?,
      externalUrl: row['external_url'] as String?,
      createdAt: DateTime.parse(_required(row, 'created_at')),
      updatedAt: DateTime.parse(_required(row, 'updated_at')),
    );
  }

  /// The column list for `from('resources').select(...)`.
  static const columns =
      'id, group_id, teacher_id, session_id, title, description, type, '
      'storage_path, file_name, file_size, mime_type, external_url, '
      'created_at, updated_at';

  final String id;
  final String groupId;
  final String teacherId;
  final String? sessionId;
  final String title;
  final String? description;
  final ResourceType type;
  final String? storagePath;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? externalUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The host shown for link resources, such as `phet.colorado.edu`.
  String? get linkHost {
    final url = externalUrl;
    if (url == null) return null;
    final host = Uri.tryParse(url)?.host;
    return host == null || host.isEmpty ? null : host;
  }

  static String _required(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing resource column', key);
  }
}

enum ByteUnit { bytes, kilobytes, megabytes, gigabytes }

/// Splits [bytes] into a display value and binary unit; applications localize
/// the unit, for example `4404019` → `(value: '4.2', unit: megabytes)`.
({String value, ByteUnit unit}) splitByteSize(int bytes) {
  const kib = 1024;
  const mib = 1024 * kib;
  const gib = 1024 * mib;
  String compact(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

  final (divisor, unit) = switch (bytes) {
    >= gib => (gib, ByteUnit.gigabytes),
    >= mib => (mib, ByteUnit.megabytes),
    >= kib => (kib, ByteUnit.kilobytes),
    _ => (1, ByteUnit.bytes),
  };
  return (value: compact(bytes / divisor), unit: unit);
}
