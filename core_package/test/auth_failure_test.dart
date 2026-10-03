import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  AuthFailureType map(Object error, AuthOperation operation) =>
      mapAuthError(error, operation).type;

  group('rate limits', () {
    test('map Auth rate-limit codes and HTTP 429', () {
      for (final operation in AuthOperation.values) {
        expect(
          map(
            const AuthApiException(
              'raw',
              statusCode: '429',
              code: 'over_sms_send_rate_limit',
            ),
            operation,
          ),
          AuthFailureType.rateLimited,
        );
        expect(
          map(const AuthApiException('raw', statusCode: '429'), operation),
          AuthFailureType.rateLimited,
        );
      }
      expect(
        map(
          const AuthApiException('raw', code: 'over_request_rate_limit'),
          AuthOperation.verifyOtp,
        ),
        AuthFailureType.rateLimited,
      );
    });
  });

  group('verification', () {
    test('maps otp_expired to expired', () {
      expect(
        map(
          const AuthApiException(
            'Token has expired or is invalid',
            statusCode: '403',
            code: 'otp_expired',
          ),
          AuthOperation.verifyOtp,
        ),
        AuthFailureType.expiredOtp,
      );
    });

    test('maps other client errors to invalid', () {
      expect(
        map(
          const AuthApiException('raw', statusCode: '400'),
          AuthOperation.verifyOtp,
        ),
        AuthFailureType.invalidOtp,
      );
    });
  });

  group('delivery', () {
    test('maps hook and provider failures when requesting', () {
      for (final code in ['sms_send_failed', 'hook_timeout']) {
        expect(
          map(
            AuthApiException('raw', statusCode: '400', code: code),
            AuthOperation.requestOtp,
          ),
          AuthFailureType.deliveryFailure,
        );
      }
      expect(
        map(
          AuthRetryableFetchException(
            message: '{"code":500,"error_code":"sms_send_failed","msg":"x"}',
            statusCode: '500',
          ),
          AuthOperation.requestOtp,
        ),
        AuthFailureType.deliveryFailure,
      );
      expect(
        map(
          const AuthApiException('Phone not allowlisted', statusCode: '403'),
          AuthOperation.requestOtp,
        ),
        AuthFailureType.deliveryFailure,
      );
    });
  });

  group('network', () {
    test('maps offline and timeout errors', () {
      for (final operation in AuthOperation.values) {
        expect(
          map(AuthRetryableFetchException(), operation),
          AuthFailureType.network,
        );
        expect(
          map(http.ClientException('offline'), operation),
          AuthFailureType.network,
        );
        expect(
          map(TimeoutException('slow'), operation),
          AuthFailureType.network,
        );
      }
    });
  });

  test('maps unrelated errors to unknown and keeps AuthFailure', () {
    expect(
      map(StateError('x'), AuthOperation.signOut),
      AuthFailureType.unknown,
    );
    expect(
      map(
        const AuthApiException('raw', statusCode: '400'),
        AuthOperation.signOut,
      ),
      AuthFailureType.unknown,
    );
    const failure = AuthFailure(AuthFailureType.invalidOtp);
    expect(mapAuthError(failure, AuthOperation.requestOtp), same(failure));
  });

  test('never exposes raw backend messages', () {
    final failure = mapAuthError(
      const AuthApiException('secret provider detail', statusCode: '500'),
      AuthOperation.requestOtp,
    );
    expect(failure.toString(), isNot(contains('secret')));
  });
}
