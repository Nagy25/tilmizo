import 'package:core_package/core_package.dart';

import '../errors/app_failure.dart';

/// Returns the authenticated user ID or throws a session-expired failure.
String requireUserId(PhoneAuthService auth) {
  final userId = auth.currentUserId;
  if (userId == null) throw const AppFailure(AppFailureType.sessionExpired);
  return userId;
}
