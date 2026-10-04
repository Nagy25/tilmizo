import '../auth/phone_auth_service.dart';
import 'app_failure.dart';

/// Returns the authenticated user ID or throws a session-expired failure.
String requireUserId(PhoneAuthService auth) {
  final userId = auth.currentUserId;
  if (userId == null) throw const AppFailure(AppFailureType.sessionExpired);
  return userId;
}
