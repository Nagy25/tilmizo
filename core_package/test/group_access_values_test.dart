import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses every known backend value', () {
    expect(JoinRequestType.fromBackend('join'), JoinRequestType.join);
    expect(
      JoinRequestType.fromBackend('device_replacement'),
      JoinRequestType.deviceReplacement,
    );
    for (final status in JoinRequestStatus.values) {
      expect(JoinRequestStatus.fromBackend(status.backendValue), status);
    }
    for (final status in MembershipStatus.values) {
      expect(MembershipStatus.fromBackend(status.backendValue), status);
    }
    expect(DevicePlatform.fromBackend('android'), DevicePlatform.android);
    expect(DevicePlatform.fromBackend('ios'), DevicePlatform.ios);
  });

  test('rejects unknown values instead of guessing', () {
    expect(
      () => JoinRequestType.fromBackend('existing_device'),
      throwsFormatException,
    );
    expect(
      () => JoinRequestStatus.fromBackend('Pending'),
      throwsFormatException,
    );
    expect(() => MembershipStatus.fromBackend('banned'), throwsFormatException);
    expect(() => DevicePlatform.fromBackend('web'), throwsFormatException);
    expect(() => DevicePlatform.fromBackend(''), throwsFormatException);
  });
}
