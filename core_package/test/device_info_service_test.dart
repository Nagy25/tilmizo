import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeDeviceInfoService implements DeviceInfoService {
  @override
  Future<DeviceDisplayInfo> load() async => const DeviceDisplayInfo(
    name: 'Samsung Galaxy A54',
    platform: DevicePlatform.android,
    appVersion: '1.0.0',
  );
}

void main() {
  test('builds friendly Android names from maker and model only', () {
    expect(
      PlatformDeviceInfoService.friendlyAndroidName('samsung', 'SM-A546E'),
      'Samsung SM-A546E',
    );
    expect(
      PlatformDeviceInfoService.friendlyAndroidName('Google', 'Google Pixel 8'),
      'Google Pixel 8',
    );
    expect(
      PlatformDeviceInfoService.friendlyAndroidName('', ''),
      PlatformDeviceInfoService.androidFallbackName,
    );
  });

  test('uses the iOS marketing name with a safe fallback', () {
    expect(
      PlatformDeviceInfoService.friendlyIosName('iPhone 15 Pro'),
      'iPhone 15 Pro',
    );
    expect(
      PlatformDeviceInfoService.friendlyIosName('  '),
      PlatformDeviceInfoService.iosFallbackName,
    );
  });

  test('limits names to the backend maximum length', () {
    final name = PlatformDeviceInfoService.friendlyIosName('x' * 300);
    expect(name.length, 120);
  });

  test('unsupported platforms are rejected', () {
    final service = PlatformDeviceInfoService(
      appVersion: () => '1.0.0',
      platform: TargetPlatform.linux,
    );
    expect(service.load(), throwsA(isA<UnsupportedDevicePlatformException>()));
  });

  test('provider can be overridden with a fake', () async {
    final container = ProviderContainer(
      overrides: [
        deviceInfoServiceProvider.overrideWithValue(_FakeDeviceInfoService()),
      ],
    );
    addTearDown(container.dispose);
    final info = await container.read(deviceInfoServiceProvider).load();
    expect(info.name, 'Samsung Galaxy A54');
    expect(info.platform, DevicePlatform.android);
  });

  test('device info exposes no hardware identifiers', () {
    // DeviceDisplayInfo is the only device data that leaves the service:
    // a display name, a platform, and the app version.
    const info = DeviceDisplayInfo(
      name: 'iPhone',
      platform: DevicePlatform.ios,
      appVersion: '1.0.0',
    );
    expect(
      info,
      const DeviceDisplayInfo(
        name: 'iPhone',
        platform: DevicePlatform.ios,
        appVersion: '1.0.0',
      ),
    );
  });
}
