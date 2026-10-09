import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth.dart';
import '../helpers/notification_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePushNotificationsService push;
  late FakeNotificationsRepository repository;

  Future<ProviderContainer> containerWith(
    Map<String, Object> stored, {
    DateTime? now,
  }) async {
    SharedPreferences.setMockInitialValues(stored);
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        phoneAuthServiceProvider.overrideWithValue(FakeAuth(userId: 'u1')),
        pushNotificationsServiceProvider.overrideWithValue(push),
        notificationsRepositoryProvider.overrideWithValue(repository),
        sharedPreferencesProvider.overrideWithValue(preferences),
        if (now != null) clockProvider.overrideWithValue(() => now),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    push = FakePushNotificationsService();
    repository = FakeNotificationsRepository();
  });

  group('permission', () {
    test('the first-run prompt shows once, never on later launches', () async {
      push.requestResult = NotificationPermissionStatus.denied;
      final first = await containerWith({});
      await first.read(notificationPermissionProvider.notifier).promptOnce();
      await first.read(notificationPermissionProvider.notifier).promptOnce();
      expect(push.requests, 1);

      final preferences = await SharedPreferences.getInstance();
      final relaunch = await containerWith({
        NotificationPermissionController.promptedKey: preferences.get(
          NotificationPermissionController.promptedKey,
        )!,
      });
      await relaunch.read(notificationPermissionProvider.notifier).promptOnce();
      expect(push.requests, 1);
    });

    test('never prompts when granted, blocked, or unsupported', () async {
      for (final status in [
        NotificationPermissionStatus.granted,
        NotificationPermissionStatus.blocked,
        NotificationPermissionStatus.unsupported,
      ]) {
        push.status = status;
        final container = await containerWith({});
        await container
            .read(notificationPermissionProvider.notifier)
            .promptOnce();
      }
      expect(push.requests, 0);
    });

    test('refresh picks up a change made in system settings', () async {
      push.status = NotificationPermissionStatus.blocked;
      final container = await containerWith({});
      expect(
        await container.read(notificationPermissionProvider.future),
        NotificationPermissionStatus.blocked,
      );

      push.status = NotificationPermissionStatus.granted;
      await container.read(notificationPermissionProvider.notifier).refresh();
      expect(
        container.read(notificationPermissionProvider).value,
        NotificationPermissionStatus.granted,
      );
    });
  });

  group('center', () {
    List<AppNotification> many(int count) => [
      for (var i = 0; i < count; i++)
        buildNotification(
          id: 'n$i',
          createdAt: DateTime.utc(2026, 10, 1).subtract(Duration(minutes: i)),
        ),
    ];

    test('pages newest first without duplicates', () async {
      repository.notifications.addAll(many(25));
      final container = await containerWith({});
      container.listen(notificationCenterProvider, (_, _) {});
      final first = await container.read(notificationCenterProvider.future);
      expect(first.notifications.first.id, 'n0');
      expect(first.hasMore, isTrue);

      // A new row shifts offsets; the overlap is dropped.
      repository.notifications.add(
        buildNotification(id: 'new', createdAt: DateTime.utc(2026, 10, 2)),
      );
      await container.read(notificationCenterProvider.notifier).loadMore();
      final state = container.read(notificationCenterProvider).value!;
      expect(state.notifications, hasLength(25));
      expect(state.notifications.map((n) => n.id).toSet(), hasLength(25));
      expect(state.hasMore, isFalse);
    });

    test('marks one read and restores it when the RPC fails', () async {
      repository.notifications.addAll(many(2));
      final container = await containerWith({});
      container.listen(notificationCenterProvider, (_, _) {});
      await container.read(notificationCenterProvider.future);
      final controller = container.read(notificationCenterProvider.notifier);

      await controller.markRead('n0');
      var items = container.read(notificationCenterProvider).value!;
      expect(items.notifications.first.isRead, isTrue);
      expect(items.notifications.last.isRead, isFalse);

      repository.markFailure = const AppFailure(AppFailureType.network);
      await expectLater(controller.markRead('n1'), throwsA(isA<AppFailure>()));
      items = container.read(notificationCenterProvider).value!;
      expect(items.notifications.last.isRead, isFalse);
    });

    test('marks all read and refreshes the badge', () async {
      repository.notifications.addAll(many(3));
      final container = await containerWith({});
      container
        ..listen(notificationCenterProvider, (_, _) {})
        ..listen(unreadNotificationCountProvider, (_, _) {});
      expect(await container.read(unreadNotificationCountProvider.future), 3);
      await container.read(notificationCenterProvider.future);

      await container.read(notificationCenterProvider.notifier).markAllRead();

      final state = container.read(notificationCenterProvider).value!;
      expect(state.hasUnread, isFalse);
      expect(await container.read(unreadNotificationCountProvider.future), 0);
    });
  });
}
