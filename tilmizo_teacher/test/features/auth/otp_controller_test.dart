import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/auth/domain/app_destination.dart';
import 'package:tilmizo_teacher/features/auth/presentation/controllers/otp_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestBackend backend;
  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    backend = TestBackend();
    now = testTime;
    container = ProviderContainer(
      overrides: [
        ...backend.overrides,
        clockProvider.overrideWithValue(() => now),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    container.listen(otpControllerProvider(testPhone), (_, _) {});
  });

  OtpController controller() =>
      container.read(otpControllerProvider(testPhone).notifier);
  OtpState state() => container.read(otpControllerProvider(testPhone));

  test('starts a visible 60-second resend countdown', () {
    expect(state().secondsRemaining, 60);
    expect(state().canResend, isFalse);

    now = now.add(const Duration(seconds: 15));
    controller().tick();
    expect(state().secondsRemaining, 45);
  });

  test('requires exactly six digits before calling Auth', () async {
    for (final code in ['', '12345', '1234567', '12a456']) {
      expect(await controller().verify(code), isNull);
      expect(state().error, OtpError.incompleteCode);
    }
    expect(backend.auth.verifications, isEmpty);
  });

  test('verifies and resolves the next destination', () async {
    final result = await controller().verify('123456');

    expect(backend.auth.verifications.single, (
      phone: testPhone,
      code: '123456',
    ));
    expect(result?.destination, AppDestination.emptyGroups);
  });

  test('is verifying while the request is pending', () async {
    backend.auth.pendingVerification = Completer();
    final future = controller().verify('123456');
    expect(state().isVerifying, isTrue);
    expect(state().canResend, isFalse);

    backend.auth.pendingVerification!.complete();
    await future;
  });

  test('reports a wrong code within the OTP lifetime as invalid', () async {
    backend.auth.verifyFailure = const AuthFailure(AuthFailureType.expiredOtp);
    now = now.add(const Duration(seconds: 20));

    expect(await controller().verify('000000'), isNull);
    expect(state().error, OtpError.invalidCode);
    expect(state().isVerifying, isFalse);
  });

  test('reports a code used after its lifetime as expired', () async {
    backend.auth.verifyFailure = const AuthFailure(AuthFailureType.invalidOtp);
    now = now.add(otpLifetime + const Duration(seconds: 1));

    expect(await controller().verify('000000'), isNull);
    expect(state().error, OtpError.expiredCode);
  });

  test('maps rate limits and network failures during verification', () async {
    backend.auth.verifyFailure = const AuthFailure(AuthFailureType.rateLimited);
    await controller().verify('123456');
    expect(state().error, OtpError.rateLimited);

    backend.auth.verifyFailure = const AuthFailure(AuthFailureType.network);
    await controller().verify('123456');
    expect(state().error, OtpError.network);
  });

  test('resend is blocked until the countdown ends', () async {
    await controller().resend();
    expect(backend.auth.requestedPhones, isEmpty);

    now = now.add(otpResendCooldown);
    controller().tick();
    expect(state().canResend, isTrue);

    await controller().resend();
    expect(backend.auth.requestedPhones, [testPhone]);
    expect(state().didResend, isTrue);
    expect(state().secondsRemaining, 60);
    expect(state().canResend, isFalse);
  });

  test('resend failures keep the action available', () async {
    now = now.add(otpResendCooldown);
    controller().tick();
    backend.auth.requestFailure = const AuthFailure(
      AuthFailureType.deliveryFailure,
    );

    await controller().resend();
    expect(state().error, OtpError.deliveryFailure);
    expect(state().canResend, isTrue);

    backend.auth.requestFailure = const AuthFailure(
      AuthFailureType.rateLimited,
    );
    await controller().resend();
    expect(state().error, OtpError.rateLimited);
  });

  test('falls back to the splash retry when resolution fails', () async {
    backend.profiles.fetchFailure = const AppFailure(AppFailureType.network);
    final result = await controller().verify('123456');

    expect(result, isNotNull);
    expect(result!.destination, isNull);
  });
}
