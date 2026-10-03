import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/auth/presentation/controllers/phone_login_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestBackend backend;

  setUp(() => backend = TestBackend());

  PhoneLoginController controllerOf(ProviderContainer container) {
    container.listen(phoneLoginControllerProvider, (_, _) {});
    return container.read(phoneLoginControllerProvider.notifier);
  }

  test('rejects an invalid number without calling Auth', () async {
    final container = backend.createContainer();
    final phone = await controllerOf(container).submit('0131234567');

    expect(phone, isNull);
    expect(
      container.read(phoneLoginControllerProvider).error,
      PhoneLoginError.invalidPhone,
    );
    expect(backend.auth.requestedPhones, isEmpty);
  });

  test('normalizes local formatting before requesting the OTP', () async {
    final container = backend.createContainer();
    final phone = await controllerOf(container).submit('010 1234-5678');

    expect(phone, testPhone);
    expect(backend.auth.requestedPhones, [testPhone]);
    expect(container.read(phoneLoginControllerProvider).error, isNull);
  });

  test('is submitting while the request is pending', () async {
    final container = backend.createContainer();
    final controller = controllerOf(container);
    backend.auth.pendingRequest = Completer();

    final future = controller.submit('01012345678');
    expect(container.read(phoneLoginControllerProvider).isSubmitting, isTrue);
    expect(await controller.submit('01012345678'), isNull);

    backend.auth.pendingRequest!.complete();
    expect(await future, testPhone);
    expect(container.read(phoneLoginControllerProvider).isSubmitting, isFalse);
    expect(backend.auth.requestedPhones, hasLength(1));
  });

  test('maps request failures to stable states', () async {
    final cases = {
      AuthFailureType.rateLimited: PhoneLoginError.rateLimited,
      AuthFailureType.deliveryFailure: PhoneLoginError.deliveryFailure,
      AuthFailureType.network: PhoneLoginError.network,
      AuthFailureType.unknown: PhoneLoginError.unknown,
    };
    for (final entry in cases.entries) {
      final backend = TestBackend();
      backend.auth.requestFailure = AuthFailure(entry.key);
      final container = backend.createContainer();
      expect(await controllerOf(container).submit('01112345678'), isNull);
      expect(container.read(phoneLoginControllerProvider).error, entry.value);
    }
  });
}
