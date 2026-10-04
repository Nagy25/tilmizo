import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profile/presentation/controllers/current_profile_controller.dart';
import 'app_router.dart';

/// Sends unauthenticated navigation to the login screen.
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._ref);

  final Ref _ref;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_ref.read(phoneAuthServiceProvider).isAuthenticated) {
      resolver.next();
      return;
    }
    resolver.next(false);
    router.replaceAll([PhoneLoginRoute()]);
  }
}

/// Prevents an incomplete profile from reaching teacher screens, including
/// through web deep links.
class CompleteProfileGuard extends AutoRouteGuard {
  CompleteProfileGuard(this._ref);

  final Ref _ref;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    try {
      final profile = await _ref.read(currentProfileProvider.future);
      if (profile.isComplete) {
        resolver.next();
        return;
      }
      resolver.next(false);
      router.replaceAll([const CompleteProfileRoute()]);
    } on AppFailure {
      resolver.next(false);
      router.replaceAll([const SplashRoute()]);
    }
  }
}

/// The OTP screen needs the phone number passed in memory; a reloaded or
/// deep-linked OTP URL returns to login instead of exposing the number in the
/// URL.
class OtpArgumentsGuard extends AutoRouteGuard {
  const OtpArgumentsGuard();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (resolver.route.args is OtpVerificationRouteArgs) {
      resolver.next();
      return;
    }
    resolver.next(false);
    router.replaceAll([PhoneLoginRoute()]);
  }
}
