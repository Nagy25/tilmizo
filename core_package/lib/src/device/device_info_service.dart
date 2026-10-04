import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../group_access/group_access_values.dart';
import '../services/app_info_service.dart';

/// Display information the teacher sees for a student's device. It contains
/// no persistent hardware identifier.
@immutable
final class DeviceDisplayInfo {
  const DeviceDisplayInfo({
    required this.name,
    required this.platform,
    required this.appVersion,
  });

  final String name;
  final DevicePlatform platform;
  final String appVersion;

  @override
  bool operator ==(Object other) =>
      other is DeviceDisplayInfo &&
      other.name == name &&
      other.platform == platform &&
      other.appVersion == appVersion;

  @override
  int get hashCode => Object.hash(name, platform, appVersion);
}

/// Thrown on platforms where student device registration is unsupported.
final class UnsupportedDevicePlatformException implements Exception {
  const UnsupportedDevicePlatformException();
}

abstract interface class DeviceInfoService {
  Future<DeviceDisplayInfo> load();
}

/// Reads only a friendly model name: manufacturer and model on Android, and
/// the marketing model name on iOS.
final class PlatformDeviceInfoService implements DeviceInfoService {
  PlatformDeviceInfoService({
    DeviceInfoPlugin? plugin,
    required String Function() appVersion,
    TargetPlatform? platform,
  }) : _plugin = plugin ?? DeviceInfoPlugin(),
       _readAppVersion = appVersion,
       _platformOverride = platform;

  static const androidFallbackName = 'Android phone';
  static const iosFallbackName = 'iPhone';
  static const _maxNameLength = 120;

  final DeviceInfoPlugin _plugin;
  final String Function() _readAppVersion;
  final TargetPlatform? _platformOverride;

  @override
  Future<DeviceDisplayInfo> load() async {
    if (kIsWeb) throw const UnsupportedDevicePlatformException();
    switch (_platformOverride ?? defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await _plugin.androidInfo;
        return DeviceDisplayInfo(
          name: friendlyAndroidName(info.manufacturer, info.model),
          platform: DevicePlatform.android,
          appVersion: _readAppVersion(),
        );
      case TargetPlatform.iOS:
        final info = await _plugin.iosInfo;
        return DeviceDisplayInfo(
          name: friendlyIosName(info.modelName),
          platform: DevicePlatform.ios,
          appVersion: _readAppVersion(),
        );
      default:
        throw const UnsupportedDevicePlatformException();
    }
  }

  @visibleForTesting
  static String friendlyAndroidName(String manufacturer, String model) {
    final maker = manufacturer.trim();
    final name = model.trim();
    if (name.isEmpty) return androidFallbackName;
    final capitalized = maker.isEmpty
        ? ''
        : '${maker[0].toUpperCase()}${maker.substring(1)}';
    final full =
        capitalized.isEmpty ||
            name.toLowerCase().startsWith(capitalized.toLowerCase())
        ? name
        : '$capitalized $name';
    return _limit(full);
  }

  @visibleForTesting
  static String friendlyIosName(String modelName) {
    final name = modelName.trim();
    return name.isEmpty ? iosFallbackName : _limit(name);
  }

  static String _limit(String value) => value.length <= _maxNameLength
      ? value
      : value.substring(0, _maxNameLength);
}

final deviceInfoServiceProvider = Provider<DeviceInfoService>(
  (ref) => PlatformDeviceInfoService(
    appVersion: () => AppInfoService.instance.version,
  ),
);
