import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_notification.dart';
import 'notifications_repository.dart';

/// Whether the OS will show this app's notifications.
enum NotificationPermissionStatus {
  granted,

  /// Not granted, but the system prompt can still be shown.
  denied,

  /// Denied and the OS will not prompt again; only system settings can
  /// enable notifications.
  blocked,

  /// Push is not available on this platform or build (for example tests,
  /// unsupported browsers, or iOS before its Firebase and APNs setup).
  unsupported,
}

/// Device push messaging and notification permission.
///
/// Implementations never throw; failures surface as `null` tokens,
/// [NotificationPermissionStatus.unsupported], or `false`.
abstract interface class PushNotificationsService {
  /// Resolves once initialization finished; `false` when push is
  /// unavailable.
  Future<bool> isAvailable();

  /// The platform reported to `register_notification_device`.
  NotificationPlatform? get platform;

  Future<NotificationPermissionStatus> permissionStatus();

  /// Shows the system prompt when the OS still allows it.
  Future<NotificationPermissionStatus> requestPermission();

  /// Opens this app's system settings page; `false` when it could not.
  Future<bool> openSettings();

  /// The FCM registration token. Never log it.
  Future<String?> getToken();

  /// Retires the current token so the next [getToken] issues a new one.
  Future<void> deleteToken();

  Stream<String> get onTokenRefresh;

  /// Messages received while the app is in the foreground. The OS does not
  /// display these.
  Stream<NotificationTarget> get onForegroundMessage;

  /// Notification taps that resumed the app from the background.
  Stream<NotificationTarget> get onNotificationOpened;

  /// The notification tap that launched the app, at most once per launch.
  Future<NotificationTarget?> takeLaunchNotification();
}

/// Starts Firebase without delaying `runApp` and exposes the resulting
/// [PushNotificationsService]. Until [start] runs, push is disabled.
abstract final class PushNotificationsBootstrap {
  /// iOS stays disabled until `GoogleService-Info.plist`, the Push
  /// Notifications capability, and an APNs key are configured. Then build
  /// with `--dart-define=IOS_PUSH_ENABLED=true`.
  static const iosEnabled = bool.fromEnvironment('IOS_PUSH_ENABLED');

  static PushNotificationsService _service =
      const DisabledPushNotificationsService();

  static PushNotificationsService get service => _service;

  /// Begins initialization on supported platforms. Web requires app-specific
  /// Firebase options and the public Web Push VAPID key. Safe to call before
  /// `runApp` without awaiting.
  static void start({FirebaseOptions? webOptions, String? webVapidKey}) {
    final platform = _supportedPlatform(webOptions, webVapidKey);
    if (platform == null) return;
    _service = FirebasePushNotificationsService(
      platform,
      _initialize(webOptions),
      webVapidKey: webVapidKey,
    );
  }

  static NotificationPlatform? _supportedPlatform(
    FirebaseOptions? webOptions,
    String? webVapidKey,
  ) {
    if (kIsWeb) {
      return webOptions != null && webVapidKey?.trim().isNotEmpty == true
          ? NotificationPlatform.web
          : null;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => NotificationPlatform.android,
      TargetPlatform.iOS when iosEnabled => NotificationPlatform.ios,
      _ => null,
    };
  }

  /// Native builds use `google-services.json` / `GoogleService-Info.plist`.
  static Future<bool> _initialize(FirebaseOptions? webOptions) async {
    try {
      await Firebase.initializeApp(options: kIsWeb ? webOptions : null)
          .timeout(const Duration(seconds: 15));
      if (kIsWeb && !await FirebaseMessaging.instance.isSupported()) {
        return false;
      }
      return true;
    } catch (error) {
      debugPrint('Push notifications unavailable: ${error.runtimeType}');
      return false;
    }
  }
}

final pushNotificationsServiceProvider = Provider<PushNotificationsService>(
  (ref) => PushNotificationsBootstrap.service,
);

/// Push is off: every query reports [NotificationPermissionStatus.unsupported].
final class DisabledPushNotificationsService
    implements PushNotificationsService {
  const DisabledPushNotificationsService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  NotificationPlatform? get platform => null;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.unsupported;

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.unsupported;

  @override
  Future<bool> openSettings() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<NotificationTarget> get onForegroundMessage => const Stream.empty();

  @override
  Stream<NotificationTarget> get onNotificationOpened => const Stream.empty();

  @override
  Future<NotificationTarget?> takeLaunchNotification() async => null;
}

/// FCM on Android, enabled iOS builds, and configured web builds.
final class FirebasePushNotificationsService
    implements PushNotificationsService {
  FirebasePushNotificationsService(
    this.platform,
    this._ready, {
    this.webVapidKey,
  });

  /// Implemented by each app's `MainActivity`; opens this app's
  /// notification settings.
  static const settingsChannel = MethodChannel('telmizo/notification_settings');

  @override
  final NotificationPlatform platform;

  final Future<bool> _ready;
  final String? webVapidKey;
  bool _launchTaken = false;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<bool> isAvailable() => _ready;

  @override
  Future<NotificationPermissionStatus> permissionStatus() => _whenReady(
    NotificationPermissionStatus.unsupported,
    () async => _status(await _messaging.getNotificationSettings()),
  );

  @override
  Future<NotificationPermissionStatus> requestPermission() =>
      _whenReady(NotificationPermissionStatus.unsupported, () async {
        if (platform == NotificationPlatform.web) {
          return _status(await _messaging.requestPermission());
        }
        final before = await _messaging.getNotificationSettings();
        final after = await _messaging.requestPermission();
        // Denied before and after: the OS showed no prompt (Android 12 and
        // older with notifications off), so only settings can enable it.
        if (before.authorizationStatus == AuthorizationStatus.denied &&
            after.authorizationStatus == AuthorizationStatus.denied) {
          return NotificationPermissionStatus.blocked;
        }
        return _status(after);
      });

  @override
  Future<bool> openSettings() async {
    try {
      return switch (platform) {
        NotificationPlatform.android =>
          await settingsChannel.invokeMethod<bool>('open') ?? false,
        NotificationPlatform.ios => await launchUrl(Uri.parse('app-settings:')),
        NotificationPlatform.web => false,
      };
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getToken() => _whenReady(
    null,
    () => platform == NotificationPlatform.web
        ? _messaging.getToken(
            vapidKey: webVapidKey,
            serviceWorkerScriptPath: 'firebase-messaging-sw.js',
          )
        : _messaging.getToken(),
  );

  @override
  Future<void> deleteToken() =>
      _whenReady(null, () => _messaging.deleteToken());

  @override
  Stream<String> get onTokenRefresh =>
      _afterReady(() => _messaging.onTokenRefresh);

  @override
  Stream<NotificationTarget> get onForegroundMessage =>
      _afterReady(() => FirebaseMessaging.onMessage.map(_target));

  @override
  Stream<NotificationTarget> get onNotificationOpened =>
      _afterReady(() => FirebaseMessaging.onMessageOpenedApp.map(_target));

  @override
  Future<NotificationTarget?> takeLaunchNotification() async {
    if (_launchTaken) return null;
    _launchTaken = true;
    final message = await _whenReady(
      null,
      () => _messaging.getInitialMessage(),
    );
    return message == null ? null : _target(message);
  }

  static NotificationTarget _target(RemoteMessage message) =>
      NotificationTarget.fromPushData(message.data);

  Future<T> _whenReady<T>(T fallback, Future<T> Function() action) async {
    try {
      if (!await _ready) return fallback;
      return await action();
    } catch (error) {
      // Plugin errors (for example a missing APNs token) must not reach UI.
      debugPrint('Push notifications call failed: ${error.runtimeType}');
      return fallback;
    }
  }

  Stream<T> _afterReady<T>(Stream<T> Function() stream) async* {
    if (await _ready) yield* stream();
  }

  /// A plain denial still allows a prompt on Android 13+, but iOS and web
  /// require settings after the browser or OS has denied permission.
  NotificationPermissionStatus _status(NotificationSettings value) =>
      switch (value.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => NotificationPermissionStatus.granted,
        AuthorizationStatus.deniedPermanently =>
          NotificationPermissionStatus.blocked,
        AuthorizationStatus.denied =>
          platform == NotificationPlatform.ios ||
                  platform == NotificationPlatform.web
              ? NotificationPermissionStatus.blocked
              : NotificationPermissionStatus.denied,
        AuthorizationStatus.notDetermined =>
          NotificationPermissionStatus.denied,
      };
}
