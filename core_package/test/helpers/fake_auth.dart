import 'dart:async';

import 'package:core_package/core_package.dart';

/// [PhoneAuthService] whose signed-in user is set directly by tests.
final class FakeAuth implements PhoneAuthService {
  FakeAuth({this.userId});

  final status = StreamController<AuthSessionStatus>.broadcast();
  String? userId;

  @override
  bool get isAuthenticated => userId != null;

  @override
  String? get currentUserId => userId;

  @override
  Stream<AuthSessionStatus> get sessionStatus => status.stream;

  void signIn(String id) {
    userId = id;
    status.add(AuthSessionStatus.authenticated);
  }

  @override
  Future<void> signOut() async {
    userId = null;
    status.add(AuthSessionStatus.unauthenticated);
  }

  @override
  Future<void> requestOtp(String egyptianE164Phone) async {}

  @override
  Future<void> verifyOtp({
    required String egyptianE164Phone,
    required String code,
  }) async {}
}
