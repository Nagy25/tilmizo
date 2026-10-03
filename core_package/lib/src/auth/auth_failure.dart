import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/network_errors.dart';

/// Stable authentication failure categories safe to present to users.
enum AuthFailureType {
  rateLimited,
  invalidOtp,
  expiredOtp,
  network,
  deliveryFailure,
  unknown,
}

/// The authentication call that produced a failure. Supabase reports several
/// failures with the same HTTP status, so the operation disambiguates them.
enum AuthOperation { requestOtp, verifyOtp, signOut }

/// An application-level authentication failure that never carries the raw
/// Supabase, Auth hook, or Meta message.
final class AuthFailure implements Exception {
  const AuthFailure(this.type);

  final AuthFailureType type;

  @override
  String toString() => 'AuthFailure(${type.name})';
}

const _rateLimitCodes = {'over_request_rate_limit', 'over_sms_send_rate_limit'};

const _deliveryCodes = {
  'sms_send_failed',
  'hook_timeout',
  'hook_timeout_after_retry',
  'hook_payload_over_size_limit',
  'hook_payload_unknown_size',
  'phone_provider_disabled',
  'provider_disabled',
  'otp_disabled',
};

/// Maps any error thrown by the Supabase Auth client to an [AuthFailure].
AuthFailure mapAuthError(Object error, AuthOperation operation) {
  if (error is AuthFailure) return error;
  if (error is TimeoutException || isNetworkError(error)) {
    return const AuthFailure(AuthFailureType.network);
  }
  if (error is! AuthException) {
    return const AuthFailure(AuthFailureType.unknown);
  }

  final status = int.tryParse(error.statusCode ?? '');
  final code = error.code ?? _codeFromBody(error.message);

  if (error is AuthRetryableFetchException && status == null) {
    return const AuthFailure(AuthFailureType.network);
  }
  if (status == 429 || _rateLimitCodes.contains(code)) {
    return const AuthFailure(AuthFailureType.rateLimited);
  }

  switch (operation) {
    case AuthOperation.requestOtp:
      // The Send SMS hook reports allowlist, validation, and Meta delivery
      // failures with 4xx/5xx statuses that Auth forwards to the client.
      if (_deliveryCodes.contains(code) || (status != null && status >= 400)) {
        return const AuthFailure(AuthFailureType.deliveryFailure);
      }
    case AuthOperation.verifyOtp:
      if (code == 'otp_expired') {
        return const AuthFailure(AuthFailureType.expiredOtp);
      }
      if (status != null && status >= 400 && status < 500) {
        return const AuthFailure(AuthFailureType.invalidOtp);
      }
    case AuthOperation.signOut:
      break;
  }
  return const AuthFailure(AuthFailureType.unknown);
}

/// Server errors arrive as [AuthRetryableFetchException] whose message is the
/// raw response body; recover the Auth `error_code` when present.
String? _codeFromBody(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final code = decoded['error_code'] ?? decoded['code'];
      if (code is String) return code;
    }
  } on FormatException {
    return null;
  }
  return null;
}
