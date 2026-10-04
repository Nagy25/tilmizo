import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// Teacher-editable group fields. Ownership, ID, and timestamps are never
/// part of a draft.
@immutable
final class GroupDraft {
  const GroupDraft._({
    required this.name,
    required this.subject,
    required this.grade,
    required this.inviteCode,
    required this.isActive,
  });

  /// Trims every value and converts blank optional values to `null`.
  /// Returns `null` when the required name is blank.
  static GroupDraft? tryCreate({
    required String name,
    String? subject,
    String? grade,
    String? inviteCode,
    bool isActive = true,
  }) {
    final trimmedName = trimToNull(name);
    if (trimmedName == null) return null;
    return GroupDraft._(
      name: trimmedName,
      subject: trimToNull(subject),
      grade: trimToNull(grade),
      inviteCode: trimToNull(inviteCode),
      isActive: isActive,
    );
  }

  final String name;
  final String? subject;
  final String? grade;

  /// Case-sensitive; preserved exactly as entered apart from trimming.
  final String? inviteCode;
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      other is GroupDraft &&
      other.name == name &&
      other.subject == subject &&
      other.grade == grade &&
      other.inviteCode == inviteCode &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(name, subject, grade, inviteCode, isActive);
}
