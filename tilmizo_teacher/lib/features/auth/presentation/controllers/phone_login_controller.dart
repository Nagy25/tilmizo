import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/development_auth_config.dart';

enum PhoneLoginError {
  invalidPhone,
  testPhoneRequired,
  rateLimited,
  deliveryFailure,
  network,
  unknown,
}

@immutable
final class PhoneLoginState {
  const PhoneLoginState({this.isSubmitting = false, this.error});

  final bool isSubmitting;
  final PhoneLoginError? error;
}

final phoneLoginControllerProvider =
    NotifierProvider.autoDispose<PhoneLoginController, PhoneLoginState>(
      PhoneLoginController.new,
    );

class PhoneLoginController extends Notifier<PhoneLoginState> {
  @override
  PhoneLoginState build() => const PhoneLoginState();

  /// Normalizes [input] and requests an OTP. Returns the E.164 number on
  /// success, or `null` with [PhoneLoginState.error] set.
  Future<String?> submit(String input) async {
    if (state.isSubmitting) return null;
    final phone = EgyptianPhone.normalize(input);
    if (phone == null) {
      state = const PhoneLoginState(error: PhoneLoginError.invalidPhone);
      return null;
    }
    if (DevelopmentAuthConfig.isReady &&
        phone != DevelopmentAuthConfig.phoneE164) {
      state = const PhoneLoginState(error: PhoneLoginError.testPhoneRequired);
      return null;
    }

    state = const PhoneLoginState(isSubmitting: true);
    try {
      await ref.read(phoneAuthServiceProvider).requestOtp(phone);
      if (ref.mounted) state = const PhoneLoginState();
      return phone;
    } on AuthFailure catch (failure) {
      if (ref.mounted) state = PhoneLoginState(error: _map(failure.type));
      return null;
    }
  }

  void clearError() {
    if (state.error != null && !state.isSubmitting) {
      state = const PhoneLoginState();
    }
  }

  static PhoneLoginError _map(AuthFailureType type) => switch (type) {
    AuthFailureType.rateLimited => PhoneLoginError.rateLimited,
    AuthFailureType.deliveryFailure => PhoneLoginError.deliveryFailure,
    AuthFailureType.network => PhoneLoginError.network,
    _ => PhoneLoginError.unknown,
  };
}
