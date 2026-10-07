import 'package:flutter/foundation.dart';

import '../classes/class_values.dart';
import 'group_resource.dart';

@immutable
final class ResourcesPage {
  const ResourcesPage({required this.resources, required this.hasMore});

  final List<GroupResource> resources;
  final bool hasMore;
}

/// A same-group class session a resource can be linked to. Sessions have no
/// title, so they are labelled by start time.
@immutable
final class ResourceSessionOption {
  const ResourceSessionOption({
    required this.id,
    required this.startsAt,
    required this.status,
  });

  /// Parses a `class_sessions` row selected with [columns].
  factory ResourceSessionOption.fromRow(Map<String, dynamic> row) =>
      ResourceSessionOption(
        id: row['id'] as String,
        startsAt: DateTime.parse(row['starts_at'] as String),
        status: SessionStatus.fromBackend(row['status'] as String),
      );

  static const columns = 'id, starts_at, status';

  final String id;
  final DateTime startsAt;
  final SessionStatus status;
}
