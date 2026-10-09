import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/store_service_providers.dart';
import 'push_notifications_service.dart';

/// Notification permission for this installation. It never gates any
/// feature: the in-app notification center works without it.
final notificationPermissionProvider =
    AsyncNotifierProvider<
      NotificationPermissionController,
      NotificationPermissionStatus
    >(NotificationPermissionController.new);

class NotificationPermissionController
    extends AsyncNotifier<NotificationPermissionStatus> {
  /// Set once the automatic prompt ran, so it never repeats on later
  /// launches or for later accounts on this device.
  static const promptedKey = 'notifications.permission_prompted';

  PushNotificationsService get _service =>
      ref.read(pushNotificationsServiceProvider);

  @override
  Future<NotificationPermissionStatus> build() =>
      ref.watch(pushNotificationsServiceProvider).permissionStatus();

  /// Re-reads the OS state, for example after returning from settings.
  Future<void> refresh() async {
    final status = await _service.permissionStatus();
    if (ref.mounted && state.value != status) state = AsyncData(status);
  }

  /// Shows the system prompt when the OS still allows it.
  Future<NotificationPermissionStatus> request() async {
    // Start the browser permission request while the button's user gesture is
    // active; waiting for preferences first can cause the prompt to be blocked.
    final pending = kIsWeb ? _service.requestPermission() : null;
    await _rememberPrompt();
    final status = await (pending ?? _service.requestPermission());
    if (ref.mounted) state = AsyncData(status);
    return status;
  }

  /// The first-run prompt: shown at most once per installation, and only
  /// while the OS can still show it.
  Future<void> promptOnce() async {
    // Browsers require a user gesture. The profile's Enable button requests
    // permission explicitly instead of prompting on automatic navigation.
    if (kIsWeb) return;
    final status = await future;
    if (status == NotificationPermissionStatus.unsupported) return;
    try {
      final store = ref.read(sharedPreferencesStoreServiceProvider);
      if (await store.read(promptedKey) == true) return;
    } catch (_) {
      // Unreadable storage: skip rather than risk prompting every launch.
      return;
    }
    if (status != NotificationPermissionStatus.denied) {
      // Already granted or blocked: never prompt for it.
      return _rememberPrompt();
    }
    await request();
  }

  /// Opens the app's system settings; `false` when that failed.
  Future<bool> openSettings() => _service.openSettings();

  Future<void> _rememberPrompt() async {
    try {
      await ref
          .read(sharedPreferencesStoreServiceProvider)
          .write(promptedKey, true);
    } catch (_) {
      // Best effort.
    }
  }
}
