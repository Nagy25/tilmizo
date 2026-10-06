/// Backend values shared by the teacher and student class flows.
///
/// Every parser throws [FormatException] for an unknown value instead of
/// guessing, so a backend change cannot silently misreport attendance.
library;

enum SessionStatus {
  scheduled('scheduled'),
  completed('completed'),
  cancelled('cancelled');

  const SessionStatus(this.backendValue);

  final String backendValue;

  static SessionStatus fromBackend(String value) =>
      _parse(values, value, (status) => status.backendValue, 'session status');
}

/// A student's mark for one session. A missing attendance row means
/// [notMarked], never [absent].
enum AttendanceStatus {
  notMarked('not_marked'),
  present('present'),
  absent('absent'),
  late('late'),
  excused('excused');

  const AttendanceStatus(this.backendValue);

  final String backendValue;

  static AttendanceStatus fromBackend(String value) => _parse(
    values,
    value,
    (status) => status.backendValue,
    'attendance status',
  );
}

enum SessionLocationType {
  physical('physical'),
  online('online');

  const SessionLocationType(this.backendValue);

  final String backendValue;

  static SessionLocationType fromBackend(String value) => _parse(
    values,
    value,
    (type) => type.backendValue,
    'session location type',
  );
}

T _parse<T>(
  List<T> values,
  String value,
  String Function(T) backendValue,
  String name,
) {
  for (final candidate in values) {
    if (backendValue(candidate) == value) return candidate;
  }
  throw FormatException('Unknown $name', value);
}
