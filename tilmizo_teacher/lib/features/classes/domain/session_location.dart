import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// Why a location value would be rejected by the backend checks.
enum SessionLocationIssue {
  missingPlace,
  placeTooLong,
  missingLink,
  invalidLink,
}

/// Where a class takes place: a physical address or an HTTPS meeting link.
///
/// Mirrors the `*_location` check constraints on schedule entries and
/// sessions, so a valid value is never rejected by the database.
@immutable
final class SessionLocation {
  const SessionLocation.physical(String this.physicalLocation)
    : type = SessionLocationType.physical,
      meetingLink = null;

  const SessionLocation.online(String this.meetingLink)
    : type = SessionLocationType.online,
      physicalLocation = null;

  static const maxPlaceLength = 500;
  static const maxLinkLength = 2048;

  final SessionLocationType type;
  final String? physicalLocation;
  final String? meetingLink;

  String get value => physicalLocation ?? meetingLink!;

  bool get isOnline => type == SessionLocationType.online;

  static SessionLocationIssue? validate(SessionLocationType type, String? raw) {
    final value = trimToNull(raw);
    switch (type) {
      case SessionLocationType.physical:
        if (value == null) return SessionLocationIssue.missingPlace;
        if (value.length > maxPlaceLength) {
          return SessionLocationIssue.placeTooLong;
        }
      case SessionLocationType.online:
        if (value == null) return SessionLocationIssue.missingLink;
        final uri = Uri.tryParse(value);
        final valid =
            value.startsWith('https://') &&
            value.length <= maxLinkLength &&
            !value.contains(RegExp(r'\s')) &&
            uri != null &&
            uri.host.isNotEmpty;
        if (!valid) return SessionLocationIssue.invalidLink;
    }
    return null;
  }

  static SessionLocation? tryCreate(SessionLocationType type, String? raw) {
    if (validate(type, raw) != null) return null;
    final value = raw!.trim();
    return type == SessionLocationType.physical
        ? SessionLocation.physical(value)
        : SessionLocation.online(value);
  }

  /// Parses the location columns of a backend row.
  static SessionLocation fromColumns(Map<String, dynamic> row) =>
      switch (SessionLocationType.fromBackend(row['location_type'] as String)) {
        SessionLocationType.physical => SessionLocation.physical(
          row['physical_location'] as String,
        ),
        SessionLocationType.online => SessionLocation.online(
          row['meeting_link'] as String,
        ),
      };

  /// The three location columns, with the unused one explicitly cleared.
  Map<String, dynamic> toColumns() => {
    'location_type': type.backendValue,
    'physical_location': physicalLocation,
    'meeting_link': meetingLink,
  };

  @override
  bool operator ==(Object other) =>
      other is SessionLocation &&
      other.type == type &&
      other.physicalLocation == physicalLocation &&
      other.meetingLink == meetingLink;

  @override
  int get hashCode => Object.hash(type, physicalLocation, meetingLink);
}
