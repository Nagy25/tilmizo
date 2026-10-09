import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../auth/auth_session_status.dart';
import '../errors/app_failure.dart';
import '../providers/clock_provider.dart';
import 'notification_permission_controller.dart';
import 'notifications_repository.dart';
import 'notifications_repository_impl.dart';
import 'push_notifications_service.dart';

/// Which application registers devices. Each app overrides this at its root
/// `ProviderScope`.
final notificationAppProvider = Provider<NotificationApp>((ref) {
  throw UnimplementedError('notificationAppProvider must be overridden');
});

enum PushRegistrationStatus {
  /// No session.
  inactive,

  /// Push is unavailable on this platform or build.
  unsupported,

  /// The OS permission is not granted.
  permissionRequired,
  registering,
  registered,

  /// The backend rejected the account for now (a teacher without groups or
  /// a student without a membership). Retried later.
  deferred,

  /// Token or network failure. Retried later.
  failed,
}

/// Keeps this installation's FCM token registered for the signed-in user.
///
/// Registration follows the session, the permission, and token refreshes.
/// It never blocks sign-in or the notification center.
final pushRegistrationProvider =
    NotifierProvider<PushRegistrationController, PushRegistrationStatus>(
      PushRegistrationController.new,
    );

class PushRegistrationController extends Notifier<PushRegistrationStatus> {
  static const revokeTimeout = Duration(seconds: 5);
  static const defaultRetryInterval = Duration(seconds: 15);

  String? _token;
  String? _userId;
  Future<void>? _running;
  bool _rerun = false;
  DateTime? _lastAttempt;

  /// Set while signing out, so a token refresh triggered by [prepareSignOut]
  /// cannot re-register the departing account.
  DateTime? _suspendedUntil;

  PushNotificationsService get _service =>
      ref.read(pushNotificationsServiceProvider);
  NotificationsRepository get _repository =>
      ref.read(notificationsRepositoryProvider);

  @override
  PushRegistrationStatus build() {
    ref.listen(authSessionStatusProvider, (_, next) {
      switch (next.value) {
        case AuthSessionStatus.authenticated:
          _suspendedUntil = null;
          unawaited(sync());
        case AuthSessionStatus.unauthenticated:
          _suspendedUntil = null;
          _forget();
          state = PushRegistrationStatus.inactive;
        case null:
          break;
      }
    });
    ref.listen(notificationPermissionProvider, (previous, next) {
      if (next.value != previous?.value && next.hasValue) unawaited(sync());
    });
    final subscription = ref
        .watch(pushNotificationsServiceProvider)
        .onTokenRefresh
        .listen(_onTokenRefresh);
    ref.onDispose(subscription.cancel);
    return PushRegistrationStatus.inactive;
  }

  /// Registers the current token when a session and permission exist.
  /// Concurrent calls coalesce into one follow-up run.
  Future<void> sync({bool force = false}) {
    if (_running case final running?) {
      _rerun = true;
      return running;
    }
    final run = _sync(force).whenComplete(() {
      _running = null;
      if (_rerun && ref.mounted) {
        _rerun = false;
        unawaited(sync());
      }
    });
    return _running = run;
  }

  /// Retries a deferred or failed registration, at most once per
  /// [minInterval], for example when the app resumes or navigates.
  Future<void> retryIfPending({
    Duration minInterval = defaultRetryInterval,
  }) async {
    if (state != PushRegistrationStatus.deferred &&
        state != PushRegistrationStatus.failed) {
      return;
    }
    if (_recentAttempt(minInterval)) return;
    await sync(force: true);
  }

  bool _recentAttempt([Duration within = defaultRetryInterval]) {
    final last = _lastAttempt;
    return last != null && ref.read(clockProvider)().difference(last) < within;
  }

  /// Revokes this device before Supabase sign-out and retires the token, so
  /// the next account on the device starts with a fresh one. Best effort and
  /// time-bounded: sign-out must never wait on push.
  Future<void> prepareSignOut() async {
    _suspendedUntil = ref
        .read(clockProvider)()
        .add(const Duration(seconds: 30));
    final service = _service;
    try {
      if (!await service.isAvailable()) return;
      final token = _token ?? await service.getToken();
      if (token != null && ref.read(phoneAuthServiceProvider).isAuthenticated) {
        await _repository.revokeDevice(token).timeout(revokeTimeout);
      }
    } catch (_) {
      // Offline or expired: the backend retires the token on delivery.
    } finally {
      _forget();
    }
    try {
      await service.deleteToken().timeout(revokeTimeout);
    } catch (_) {
      // A stale token is re-issued on the next registration attempt.
    }
  }

  void _forget() {
    _token = null;
    _userId = null;
    _lastAttempt = null;
  }

  Future<void> _sync(bool force) async {
    if (_suspendedUntil case final until?
        when ref.read(clockProvider)().isBefore(until)) {
      return;
    }
    final service = _service;
    if (!await service.isAvailable()) {
      return _set(PushRegistrationStatus.unsupported);
    }
    final userId = ref.read(phoneAuthServiceProvider).currentUserId;
    if (userId == null) return _set(PushRegistrationStatus.inactive);
    if (await service.permissionStatus() !=
        NotificationPermissionStatus.granted) {
      return _set(PushRegistrationStatus.permissionRequired);
    }
    final token = await service.getToken();
    if (token == null) return _set(PushRegistrationStatus.failed);
    if (!force &&
        state == PushRegistrationStatus.registered &&
        token == _token &&
        userId == _userId) {
      return;
    }
    // Startup fires several triggers at once; an ineligible account is only
    // asked again through the throttled [retryIfPending].
    if (!force &&
        state == PushRegistrationStatus.deferred &&
        _recentAttempt()) {
      return;
    }
    _set(PushRegistrationStatus.registering);
    _lastAttempt = ref.read(clockProvider)();
    try {
      await _register(token, userId);
    } on AppFailure catch (failure) {
      if (failure.type != AppFailureType.rejected) {
        return _set(_statusFor(failure));
      }
      // The token is still registered to the previous account on this
      // device (its revoke failed). Rotate it once and register the new one.
      await service.deleteToken();
      final fresh = await service.getToken();
      if (fresh == null || fresh == token) {
        return _set(PushRegistrationStatus.failed);
      }
      try {
        await _register(fresh, userId);
      } on AppFailure catch (failure) {
        _set(_statusFor(failure));
      }
    }
  }

  Future<void> _register(String token, String userId) async {
    final platform = _service.platform!;
    await _repository.registerDevice(
      token: token,
      platform: platform,
      app: ref.read(notificationAppProvider),
    );
    _token = token;
    _userId = userId;
    _set(PushRegistrationStatus.registered);
  }

  Future<void> _onTokenRefresh(String token) async {
    final previous = _token;
    if (previous == null || previous == token) return unawaited(sync());
    try {
      await _repository.revokeDevice(previous).timeout(revokeTimeout);
    } catch (_) {
      // The backend retires invalid tokens on delivery.
    }
    await sync(force: true);
  }

  static PushRegistrationStatus _statusFor(AppFailure failure) =>
      failure.type == AppFailureType.notEligible
      ? PushRegistrationStatus.deferred
      : PushRegistrationStatus.failed;

  void _set(PushRegistrationStatus status) {
    if (ref.mounted) state = status;
  }
}
