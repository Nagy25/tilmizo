import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_destination.dart';
import 'app_flow_controller.dart';

const otpLength = 6;
const otpResendCooldown = Duration(seconds: 60);

/// Configured Supabase OTP lifetime. Auth reports wrong and expired codes with
/// the same error, so the elapsed time distinguishes them for the user.
const otpLifetime = Duration(seconds: 60);

enum OtpError {
  incompleteCode,
  invalidCode,
  expiredCode,
  rateLimited,
  deliveryFailure,
  network,
  unknown,
}

@immutable
final class OtpState {
  const OtpState({
    required this.secondsRemaining,
    this.isVerifying = false,
    this.isResending = false,
    this.didResend = false,
    this.error,
  });

  final int secondsRemaining;
  final bool isVerifying;
  final bool isResending;
  final bool didResend;
  final OtpError? error;

  bool get canResend => secondsRemaining == 0 && !isResending && !isVerifying;

  OtpState copyWith({
    int? secondsRemaining,
    bool? isVerifying,
    bool? isResending,
    bool? didResend,
    OtpError? Function()? error,
  }) => OtpState(
    secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    isVerifying: isVerifying ?? this.isVerifying,
    isResending: isResending ?? this.isResending,
    didResend: didResend ?? this.didResend,
    error: error == null ? this.error : error(),
  );
}

/// OTP verification and resend countdown for one E.164 phone number.
final otpControllerProvider = NotifierProvider.autoDispose
    .family<OtpController, OtpState, String>(OtpController.new);

/// Outcome of a successful verification: the resolved destination, or `null`
/// when it could not be resolved yet and the splash screen should retry.
typedef OtpVerificationResult = ({AppDestination? destination});

class OtpController extends Notifier<OtpState> {
  OtpController(this.phone);

  final String phone;
  Timer? _timer;
  late DateTime _sentAt;

  DateTime _now() => ref.read(clockProvider)();

  @override
  OtpState build() {
    ref.onDispose(() => _timer?.cancel());
    _sentAt = _now();
    _startTimer();
    return OtpState(secondsRemaining: otpResendCooldown.inSeconds);
  }

  /// Recomputes the resend countdown from the clock.
  @visibleForTesting
  void tick() {
    final elapsed = _now().difference(_sentAt);
    final remaining = otpResendCooldown - elapsed;
    final seconds = remaining.isNegative
        ? 0
        : (remaining.inMilliseconds / 1000).ceil();
    if (seconds == 0) _timer?.cancel();
    if (seconds != state.secondsRemaining) {
      state = state.copyWith(secondsRemaining: seconds);
    }
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(error: () => null);
  }

  /// Verifies [code]. Returns `null` on failure with [OtpState.error] set.
  Future<OtpVerificationResult?> verify(String code) async {
    if (state.isVerifying) return null;
    if (!RegExp('^[0-9]{$otpLength}\$').hasMatch(code)) {
      state = state.copyWith(error: () => OtpError.incompleteCode);
      return null;
    }

    state = state.copyWith(isVerifying: true, error: () => null);
    try {
      await ref
          .read(phoneAuthServiceProvider)
          .verifyOtp(egyptianE164Phone: phone, code: code);
    } on AuthFailure catch (failure) {
      if (ref.mounted) {
        state = state.copyWith(
          isVerifying: false,
          error: () => _mapVerifyFailure(failure.type),
        );
      }
      return null;
    }

    ref.read(resetSessionDataProvider)();
    AppDestination? destination;
    try {
      destination = await resolveAppDestination(ref);
    } on AppFailure {
      destination = null;
    }
    return (destination: destination);
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    state = state.copyWith(isResending: true, error: () => null);
    try {
      await ref.read(phoneAuthServiceProvider).requestOtp(phone);
      if (!ref.mounted) return;
      _sentAt = _now();
      state = OtpState(
        secondsRemaining: otpResendCooldown.inSeconds,
        didResend: true,
      );
      _startTimer();
    } on AuthFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isResending: false,
        error: () => switch (failure.type) {
          AuthFailureType.rateLimited => OtpError.rateLimited,
          AuthFailureType.deliveryFailure => OtpError.deliveryFailure,
          AuthFailureType.network => OtpError.network,
          _ => OtpError.unknown,
        },
      );
    }
  }

  OtpError _mapVerifyFailure(AuthFailureType type) {
    final codeExpired = _now().difference(_sentAt) >= otpLifetime;
    return switch (type) {
      AuthFailureType.invalidOtp || AuthFailureType.expiredOtp =>
        codeExpired ? OtpError.expiredCode : OtpError.invalidCode,
      AuthFailureType.rateLimited => OtpError.rateLimited,
      AuthFailureType.network => OtpError.network,
      AuthFailureType.deliveryFailure => OtpError.deliveryFailure,
      AuthFailureType.unknown => OtpError.unknown,
    };
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }
}
