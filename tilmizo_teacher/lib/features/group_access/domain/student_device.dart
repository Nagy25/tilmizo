import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// Teacher-visible device details: a display name and platform only. The
/// installation identifier and its hash are never available to clients.
@immutable
final class StudentDevice {
  const StudentDevice({
    required this.name,
    required this.platform,
    this.appVersion,
  });

  final String name;
  final DevicePlatform platform;
  final String? appVersion;

  @override
  bool operator ==(Object other) =>
      other is StudentDevice &&
      other.name == name &&
      other.platform == platform &&
      other.appVersion == appVersion;

  @override
  int get hashCode => Object.hash(name, platform, appVersion);
}
