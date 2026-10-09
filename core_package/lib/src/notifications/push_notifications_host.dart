import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'app_notification.dart';
import 'notification_center_controller.dart';
import 'notification_permission_controller.dart';
import 'push_notifications_service.dart';
import 'push_registration_controller.dart';

/// App-wide push wiring, placed once above the router's pages.
///
/// It keeps device registration alive, refreshes the badge and center on
/// resume and foreground messages, and queues notification taps until the
/// app reaches its home screen ([isAtHome], re-checked whenever [readiness]
/// notifies). There it also shows the first-run permission prompt once.
class PushNotificationsHost extends ConsumerStatefulWidget {
  const PushNotificationsHost({
    super.key,
    required this.readiness,
    required this.isAtHome,
    required this.openTarget,
    required this.child,
    this.onForegroundMessage,
  });

  /// Notifies when [isAtHome] may have changed, typically the router.
  final Listenable readiness;

  /// Whether startup finished and the home screen is the base route.
  final bool Function() isAtHome;

  /// Navigates to a tapped notification's destination.
  final Future<void> Function(NotificationTarget target) openTarget;

  /// A restrained in-app indication; the OS shows nothing in the foreground.
  final void Function(NotificationTarget target)? onForegroundMessage;

  final Widget child;

  @override
  ConsumerState<PushNotificationsHost> createState() =>
      _PushNotificationsHostState();
}

class _PushNotificationsHostState extends ConsumerState<PushNotificationsHost> {
  final _subscriptions = <StreamSubscription<NotificationTarget>>[];
  late final AppLifecycleListener _lifecycle;
  bool _prompted = false;
  bool _opening = false;

  bool get _signedIn => ref.read(phoneAuthServiceProvider).isAuthenticated;

  @override
  void initState() {
    super.initState();
    // Registration follows the session and permission while the app runs.
    ref.listenManual(pushRegistrationProvider, (_, _) {});
    ref.listenManual(pendingNotificationOpenProvider, (_, next) {
      if (next != null) _onReadinessChanged();
    });
    final service = ref.read(pushNotificationsServiceProvider);
    _subscriptions
      ..add(service.onForegroundMessage.listen(_onForegroundMessage))
      ..add(service.onNotificationOpened.listen(_queue));
    unawaited(
      service.takeLaunchNotification().then((target) {
        if (target != null && mounted) _queue(target);
      }),
    );
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    widget.readiness.addListener(_onReadinessChanged);
  }

  @override
  void didUpdateWidget(PushNotificationsHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readiness != widget.readiness) {
      oldWidget.readiness.removeListener(_onReadinessChanged);
      widget.readiness.addListener(_onReadinessChanged);
    }
  }

  @override
  void dispose() {
    widget.readiness.removeListener(_onReadinessChanged);
    _lifecycle.dispose();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  void _onResume() {
    // Settings may have changed the permission while the app was away.
    unawaited(ref.read(notificationPermissionProvider.notifier).refresh());
    unawaited(ref.read(pushRegistrationProvider.notifier).retryIfPending());
    if (_signedIn) ref.refreshNotifications();
  }

  void _onForegroundMessage(NotificationTarget target) {
    if (!_signedIn) return;
    ref.refreshNotifications();
    widget.onForegroundMessage?.call(target);
  }

  void _queue(NotificationTarget target) {
    ref.read(pendingNotificationOpenProvider.notifier).set(target);
    if (_signedIn) ref.refreshNotifications();
  }

  void _onReadinessChanged() {
    if (!mounted || !_signedIn || !widget.isAtHome()) return;
    unawaited(ref.read(pushRegistrationProvider.notifier).retryIfPending());
    // After this frame, so the prompt appears over the rendered home screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterHomeFrame());
  }

  Future<void> _afterHomeFrame() async {
    if (!mounted || !_signedIn || !widget.isAtHome()) return;
    if (!_opening) {
      final target = ref.read(pendingNotificationOpenProvider.notifier).take();
      if (target != null) {
        _opening = true;
        try {
          await widget.openTarget(target);
        } finally {
          _opening = false;
        }
        return;
      }
    }
    if (!_prompted) {
      _prompted = true;
      await ref.read(notificationPermissionProvider.notifier).promptOnce();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
