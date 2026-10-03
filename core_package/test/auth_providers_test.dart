import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakePhoneAuthService implements PhoneAuthService {
  final controller = StreamController<AuthSessionStatus>.broadcast();
  final requested = <String>[];
  bool signedIn = false;

  @override
  bool get isAuthenticated => signedIn;

  @override
  String? get currentUserId => signedIn ? 'teacher-1' : null;

  @override
  Stream<AuthSessionStatus> get sessionStatus => controller.stream;

  @override
  Future<void> requestOtp(String egyptianE164Phone) async {
    requested.add(egyptianE164Phone);
  }

  @override
  Future<void> verifyOtp({
    required String egyptianE164Phone,
    required String code,
  }) async {
    signedIn = true;
    controller.add(AuthSessionStatus.authenticated);
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
    controller.add(AuthSessionStatus.unauthenticated);
  }
}

void main() {
  test('phoneAuthServiceProvider can be overridden with a fake', () async {
    final fake = _FakePhoneAuthService();
    final container = ProviderContainer(
      overrides: [phoneAuthServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final service = container.read(phoneAuthServiceProvider);
    expect(service, same(fake));

    await service.requestOtp('+201012345678');
    expect(fake.requested, ['+201012345678']);
  });

  test('authSessionStatusProvider follows the overridden service', () async {
    final fake = _FakePhoneAuthService();
    final container = ProviderContainer(
      overrides: [phoneAuthServiceProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final statuses = <AuthSessionStatus>[];
    container.listen(
      authSessionStatusProvider,
      (_, next) => next.whenData(statuses.add),
    );

    await fake.verifyOtp(egyptianE164Phone: '+201012345678', code: '123456');
    await fake.signOut();
    await pumpEventQueue();

    expect(statuses, [
      AuthSessionStatus.authenticated,
      AuthSessionStatus.unauthenticated,
    ]);
  });
}
