import 'package:flutter/foundation.dart';

@immutable
final class TeacherProfile {
  const TeacherProfile({
    required this.id,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.fullName,
    this.teachingSubject,
    this.avatarUrl,
  });

  final String id;
  final String? fullName;
  final String phone;
  final String? teachingSubject;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Mirrors the backend definition: a nonblank name, a verified phone, and a
  /// nonblank teaching subject.
  bool get isComplete =>
      (fullName?.trim().isNotEmpty ?? false) &&
      phone.isNotEmpty &&
      (teachingSubject?.trim().isNotEmpty ?? false);

  /// The first word of the name, used for greetings.
  String? get firstName {
    final name = fullName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  bool operator ==(Object other) =>
      other is TeacherProfile &&
      other.id == id &&
      other.fullName == fullName &&
      other.phone == phone &&
      other.teachingSubject == teachingSubject &&
      other.avatarUrl == avatarUrl &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    fullName,
    phone,
    teachingSubject,
    avatarUrl,
    createdAt,
    updatedAt,
  );
}
