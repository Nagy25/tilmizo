import 'auth_session_status.dart';

/// Phone-number authentication backed by a one-time code.
///
/// Implementations throw only [AuthFailure]; raw backend exceptions never
/// reach callers.
abstract interface class PhoneAuthService {
  bool get isAuthenticated;
  String? get currentUserId;
  Stream<AuthSessionStatus> get sessionStatus;

  Future<void> requestOtp(String egyptianE164Phone);
  Future<void> verifyOtp({
    required String egyptianE164Phone,
    required String code,
  });
  Future<void> signOut();
}
