/// Backend values shared by the teacher and student group-access flows.
///
/// Every parser throws [FormatException] for an unknown value instead of
/// guessing, so a backend change cannot silently grant or hide access.
library;

enum JoinRequestType {
  join('join'),
  deviceReplacement('device_replacement');

  const JoinRequestType(this.backendValue);

  final String backendValue;

  static JoinRequestType fromBackend(String value) =>
      _parse(values, value, (type) => type.backendValue, 'join request type');
}

enum JoinRequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const JoinRequestStatus(this.backendValue);

  final String backendValue;

  static JoinRequestStatus fromBackend(String value) => _parse(
    values,
    value,
    (status) => status.backendValue,
    'join request status',
  );
}

enum MembershipStatus {
  active('active'),
  suspended('suspended'),
  removed('removed');

  const MembershipStatus(this.backendValue);

  final String backendValue;

  static MembershipStatus fromBackend(String value) => _parse(
    values,
    value,
    (status) => status.backendValue,
    'membership status',
  );
}

enum DevicePlatform {
  android('android'),
  ios('ios');

  const DevicePlatform(this.backendValue);

  final String backendValue;

  static DevicePlatform fromBackend(String value) => _parse(
    values,
    value,
    (platform) => platform.backendValue,
    'device platform',
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
