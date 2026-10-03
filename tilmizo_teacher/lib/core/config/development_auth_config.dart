import 'package:core_package/core_package.dart';

/// Temporary Supabase test-phone configuration for local development.
///
/// Supabase still performs OTP verification and creates a real authenticated
/// session. Its hosted test-phone mapping bypasses SMS/WhatsApp delivery.
///
/// TODO(auth-production): Before release, remove the test phone/OTP mapping
/// from Supabase, set [enabled] to false, remove the test values from the
/// application's environment file, and configure an approved OTP provider.
abstract final class DevelopmentAuthConfig {
  static const bool enabled = bool.fromEnvironment(
    'ENABLE_TEST_PHONE_AUTH',
    defaultValue: false,
  );

  static const String _phone = String.fromEnvironment('TEST_PHONE_NUMBER');
  static const String _otp = String.fromEnvironment('TEST_PHONE_OTP');

  static String? get phoneE164 =>
      enabled && EgyptianPhone.isE164(_phone) ? _phone : null;

  static String? get localPhone {
    final phone = phoneE164;
    return phone == null ? null : EgyptianPhone.formatLocal(phone);
  }

  static String? get otp =>
      enabled && RegExp(r'^[0-9]{6}$').hasMatch(_otp) ? _otp : null;

  static bool get isReady => phoneE164 != null && otp != null;
}
