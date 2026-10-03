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
  });

  final String id;
  final String name;
  final String? subject;
  final String? grade;
  final String? inviteCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is TeacherGroup &&
      other.id == id &&
      other.name == name &&
      other.subject == subject &&
      other.grade == grade &&
      other.inviteCode == inviteCode &&
      other.isActive == isActive &&
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
    createdAt,
    updatedAt,
  );
}
