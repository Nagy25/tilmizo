import 'package:flutter/foundation.dart';

import '../../../core/text_normalization.dart';

/// The teacher-editable profile fields. The verified phone, ID, and
/// timestamps are intentionally absent.
@immutable
final class ProfileUpdate {
  const ProfileUpdate._({
    required this.fullName,
    required this.teachingSubject,
  });

  /// Trims input; returns `null` when a required field is blank.
  static ProfileUpdate? tryCreate({
    required String fullName,
    required String teachingSubject,
  }) {
    final name = trimToNull(fullName);
    final subject = trimToNull(teachingSubject);
    if (name == null || subject == null) return null;
    return ProfileUpdate._(fullName: name, teachingSubject: subject);
  }

  final String fullName;
  final String teachingSubject;

  @override
  bool operator ==(Object other) =>
      other is ProfileUpdate &&
      other.fullName == fullName &&
      other.teachingSubject == teachingSubject;

  @override
  int get hashCode => Object.hash(fullName, teachingSubject);
}
