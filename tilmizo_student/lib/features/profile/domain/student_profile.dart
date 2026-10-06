import 'package:flutter/foundation.dart';

@immutable
final class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.phone,
    this.fullName,
    this.avatarUrl,
    this.updatedAt,
  });

  final String id;
  final String? fullName;

  /// The verified Egyptian E.164 number; never client-editable.
  final String phone;
  final String? avatarUrl;
  final DateTime? updatedAt;

  /// A student needs only a nonblank name and the verified phone.
  bool get isComplete =>
      (fullName?.trim().isNotEmpty ?? false) && phone.isNotEmpty;

  String? get firstName {
    final name = fullName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  bool operator ==(Object other) =>
      other is StudentProfile &&
      other.id == id &&
      other.fullName == fullName &&
      other.phone == phone &&
      other.avatarUrl == avatarUrl &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, fullName, phone, avatarUrl, updatedAt);
}
