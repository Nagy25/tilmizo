import 'package:flutter/foundation.dart';

/// One row of `public.announcements`, as visible to the signed-in user under
/// RLS: the owning teacher, or a student whose current session is approved.
@immutable
final class Announcement {
  const Announcement({
    required this.id,
    required this.groupId,
    required this.teacherId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parses a Data API or RPC row selected with [columns]. Throws
  /// [FormatException] when a required column is missing or malformed.
  factory Announcement.fromRow(Map<String, dynamic> row) => Announcement(
    id: _required(row, 'id'),
    groupId: _required(row, 'group_id'),
    teacherId: _required(row, 'teacher_id'),
    title: _required(row, 'title'),
    body: _required(row, 'body'),
    createdAt: DateTime.parse(_required(row, 'created_at')).toUtc(),
    updatedAt: DateTime.parse(_required(row, 'updated_at')).toUtc(),
  );

  /// The column list for `from('announcements').select(...)`.
  static const columns =
      'id, group_id, teacher_id, title, body, created_at, updated_at';

  /// Backend `char_length` limits of the required, non-blank columns.
  static const titleMaxLength = 200;
  static const bodyMaxLength = 10000;

  final String id;
  final String groupId;
  final String teacherId;
  final String title;
  final String body;

  /// Publication time.
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether the teacher changed the title or body after publishing. Both
  /// timestamps come from the same `now()` on insert.
  bool get isEdited => updatedAt.isAfter(createdAt);

  @override
  bool operator ==(Object other) =>
      other is Announcement &&
      other.id == id &&
      other.groupId == groupId &&
      other.teacherId == teacherId &&
      other.title == title &&
      other.body == body &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, groupId, teacherId, title, body, createdAt, updatedAt);

  static String _required(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing announcement column', key);
  }
}
