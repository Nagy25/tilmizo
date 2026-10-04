import 'package:flutter/foundation.dart';

/// Group details readable only from the approved session.
@immutable
final class ApprovedGroup {
  const ApprovedGroup({
    required this.id,
    required this.name,
    this.subject,
    this.grade,
  });

  final String id;
  final String name;
  final String? subject;
  final String? grade;

  @override
  bool operator ==(Object other) =>
      other is ApprovedGroup &&
      other.id == id &&
      other.name == name &&
      other.subject == subject &&
      other.grade == grade;

  @override
  int get hashCode => Object.hash(id, name, subject, grade);
}
