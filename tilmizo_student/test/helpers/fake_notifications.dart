import 'dart:async';

import 'package:core_package/core_package.dart';

// Mirrors core_package/test/helpers/notification_fakes.dart.

const uuidA = '11111111-1111-4111-8111-111111111111';
const uuidB = '22222222-2222-4222-8222-222222222222';

AppNotification buildNotification({
  String id = 'n1',
  NotificationEventType eventType = NotificationEventType.homeworkNew,
  String? groupId = 'group-1',
  String? targetId = uuidA,
  String title = 'واجب جديد',
  String? body,
  DateTime? createdAt,
  DateTime? readAt,
}) => AppNotification(
  id: id,
  eventType: eventType,
  groupId: groupId,
  targetId: targetId,
  title: title,
  body: body,
  createdAt: createdAt ?? DateTime.utc(2026, 10, 1, 9),
  readAt: readAt,
);

/// In-memory [NotificationsRepository] following the RPC contract.
final class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository([List<AppNotification>? notifications])
    : notifications = [...?notifications];

  final List<AppNotification> notifications;
  final registered = <({String token, String platform, String app})>[];
  final revoked = <String>[];
  final calls = <String>[];

  AppFailure? fetchFailure;
  AppFailure? markFailure;

  /// Failures thrown by the next registrations, in order.
  final registerFailures = <AppFailure>[];
  AppFailure? revokeFailure;

  int get unread => notifications.where((n) => !n.isRead).length;

  @override
  Future<NotificationsPage> fetchNotifications({
    int offset = 0,
    int limit = 20,
  }) async {
    calls.add('fetch:$offset');
    if (fetchFailure case final failure?) throw failure;
    final sorted = [...notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = sorted.skip(offset).take(limit).toList();
    return NotificationsPage(
      notifications: page,
      hasMore: page.length == limit,
    );
  }

  @override
  Future<int> fetchUnreadCount() async {
    calls.add('count');
    if (fetchFailure case final failure?) throw failure;
    return unread;
  }

  @override
  Future<DateTime> markRead(String notificationId) async {
    calls.add('markRead:$notificationId');
    if (markFailure case final failure?) throw failure;
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index < 0) throw const AppFailure(AppFailureType.notFound);
    final readAt = DateTime.utc(2026, 10, 2);
    notifications[index] = notifications[index].markedRead(readAt);
    return notifications[index].readAt!;
  }

  @override
  Future<int> markAllRead() async {
    calls.add('markAllRead');
    if (markFailure case final failure?) throw failure;
    final count = unread;
    for (var i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].markedRead(DateTime.utc(2026, 10, 2));
    }
    return count;
  }

  @override
  Future<void> registerDevice({
    required String token,
    required NotificationPlatform platform,
    required NotificationApp app,
  }) async {
    calls.add('register');
    if (registerFailures.isNotEmpty) throw registerFailures.removeAt(0);
    registered.add((token: token, platform: platform.value, app: app.value));
  }

  @override
  Future<void> revokeDevice(String token) async {
    calls.add('revoke');
    if (revokeFailure case final failure?) throw failure;
    revoked.add(token);
  }
}

/// Controllable push messaging and permission state.
final class FakePushNotificationsService implements PushNotificationsService {
  FakePushNotificationsService({
    this.status = NotificationPermissionStatus.denied,
    this.requestResult = NotificationPermissionStatus.granted,
    this.token = 'token-1',
    this.launchTarget,
  });

  NotificationPermissionStatus status;

  /// False behaves like web or an unconfigured iOS build.
  bool available = true;

  /// What the next system prompt resolves to.
  NotificationPermissionStatus requestResult;
  String? token;
  NotificationTarget? launchTarget;
  bool settingsOpen = true;
  int requests = 0;
  int settingsOpened = 0;
  int deletedTokens = 0;
  int _nextToken = 2;

  final tokenRefresh = StreamController<String>.broadcast();
  final foreground = StreamController<NotificationTarget>.broadcast();
  final opened = StreamController<NotificationTarget>.broadcast();

  @override
  Future<bool> isAvailable() async => available;

  @override
  NotificationPlatform get platform => NotificationPlatform.android;

  @override
  Future<NotificationPermissionStatus> permissionStatus() async => status;

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    requests++;
    return status = requestResult;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return settingsOpen;
  }

  @override
  Future<String?> getToken() async => token;

  /// Like FCM, the next [getToken] returns a different token.
  @override
  Future<void> deleteToken() async {
    deletedTokens++;
    token = 'token-${_nextToken++}';
  }

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  @override
  Stream<NotificationTarget> get onForegroundMessage => foreground.stream;

  @override
  Stream<NotificationTarget> get onNotificationOpened => opened.stream;

  @override
  Future<NotificationTarget?> takeLaunchNotification() async {
    final target = launchTarget;
    launchTarget = null;
    return target;
  }
}

/// Maps target IDs to the group RLS would return; anything else is hidden.
final class FakeNotificationTargetLookup implements NotificationTargetLookup {
  FakeNotificationTargetLookup([Map<String, String>? visible])
    : visible = {...?visible};

  final Map<String, String> visible;
  AppFailure? failure;

  @override
  Future<String?> visibleGroupId(NotificationTarget target) async {
    if (failure case final failure?) throw failure;
    return visible[target.targetId];
  }
}
