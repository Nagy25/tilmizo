import 'package:supabase_flutter/supabase_flutter.dart';

import '../phone/egyptian_phone.dart';
import 'auth_failure.dart';
import 'auth_session_status.dart';
import 'phone_auth_service.dart';

/// [PhoneAuthService] using Supabase phone OTP.
///
/// The OTP is requested and verified through the standard Supabase phone flow.
/// Production environments may deliver it through the configured Send SMS
/// hook. Supabase-hosted test-phone mappings bypass delivery while preserving
/// real verification, sessions, profile triggers, and RLS behavior. Session
/// persistence and refresh are owned by `supabase_flutter`.
final class SupabasePhoneAuthService implements PhoneAuthService {
  SupabasePhoneAuthService(
    this._auth, {
    this._onBeforeSignOut,
    this._onSignedOut,
  });

  final GoTrueClient _auth;

  /// Runs while the session is still valid, for example to revoke this
  /// device's push token. It must be time-bounded; failures are ignored.
  final Future<void> Function()? _onBeforeSignOut;

  /// Runs after a successful sign-out, for example to clear cached files.
  final Future<void> Function()? _onSignedOut;

  @override
  bool get isAuthenticated => _auth.currentSession != null;

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  Stream<AuthSessionStatus> get sessionStatus => _auth.onAuthStateChange
      .map(
        (state) => state.session == null
            ? AuthSessionStatus.unauthenticated
            : AuthSessionStatus.authenticated,
      )
      .distinct();

  @override
  Future<void> requestOtp(String egyptianE164Phone) async {
    _assertE164(egyptianE164Phone);
    try {
      await _auth.signInWithOtp(phone: egyptianE164Phone);
    } catch (error) {
      throw mapAuthError(error, AuthOperation.requestOtp);
    }
  }

  @override
  Future<void> verifyOtp({
    required String egyptianE164Phone,
    required String code,
  }) async {
    _assertE164(egyptianE164Phone);
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      throw const AuthFailure(AuthFailureType.invalidOtp);
    }
    try {
      final response = await _auth.verifyOTP(
        phone: egyptianE164Phone,
        token: code,
        type: OtpType.sms,
      );
      if (response.session == null) {
        throw const AuthFailure(AuthFailureType.invalidOtp);
      }
    } catch (error) {
      throw mapAuthError(error, AuthOperation.verifyOtp);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _onBeforeSignOut?.call();
    } catch (_) {
      // Pre-sign-out cleanup must not block logout.
    }
    try {
      await _auth.signOut();
    } catch (error) {
      throw mapAuthError(error, AuthOperation.signOut);
    }
    try {
      await _onSignedOut?.call();
    } catch (_) {
      // The session is gone; a cleanup failure must not block logout.
    }
  }

  void _assertE164(String phone) {
    if (!EgyptianPhone.isE164(phone)) {
      throw ArgumentError.value(
        '<redacted>',
        'egyptianE164Phone',
        'Must be an Egyptian mobile number in E.164 format',
      );
    }
  }
}
