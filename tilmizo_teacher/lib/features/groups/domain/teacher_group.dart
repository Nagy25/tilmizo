import 'package:flutter/foundation.dart';

@immutable
final class TeacherGroup {
  const TeacherGroup({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.subject,
    this.grade,
    this.inviteCode,
    this.isSuspended = false,
  });

  final String id;
  final String name;
  final String? subject;
  final String? grade;
  final String? inviteCode;

  /// Archived groups are inactive and read-only history.
  final bool isActive;

  /// A paused active group: no new sessions or payment amounts, while
  /// existing records can still be marked or corrected.
  final bool isSuspended;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether new sessions and payment amounts may be created.
  bool get acceptsNewEntries => isActive && !isSuspended;

  @override
  bool operator ==(Object other) =>
      other is TeacherGroup &&
      other.id == id &&
      other.name == name &&
      other.subject == subject &&
      other.grade == grade &&
      other.inviteCode == inviteCode &&
      other.isActive == isActive &&
      other.isSuspended == isSuspended &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    subject,
    grade,
    inviteCode,
    isActive,
    isSuspended,
    createdAt,
    updatedAt,
  );
}
