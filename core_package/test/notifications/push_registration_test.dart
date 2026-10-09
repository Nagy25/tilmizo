import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth.dart';
import '../helpers/notification_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuth auth;
  late FakePushNotificationsService push;
  late FakeNotificationsRepository repository;
  late DateTime now;
  late ProviderContainer container;

  Future<ProviderContainer> start({
    NotificationApp app = NotificationApp.student,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        phoneAuthServiceProvider.overrideWithValue(auth),
        pushNotificationsServiceProvider.overrideWithValue(push),
        notificationsRepositoryProvider.overrideWithValue(repository),
        notificationAppProvider.overrideWithValue(app),
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(() => now),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    container.listen(pushRegistrationProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  PushRegistrationController controller() =>
      container.read(pushRegistrationProvider.notifier);
  PushRegistrationStatus status() => container.read(pushRegistrationProvider);

  setUp(() {
    auth = FakeAuth();
    push = FakePushNotificationsService(
      status: NotificationPermissionStatus.granted,
    );
    repository = FakeNotificationsRepository();
    now = DateTime.utc(2026, 10, 1, 9);
  });

  test('registers once a session and permission exist', () async {
    await start(app: NotificationApp.teacher);
    expect(repository.registered, isEmpty);

    auth.signIn('teacher-1');
    await pumpEventQueue();

    expect(repository.registered, [
      (token: 'token-1', platform: 'android', app: 'teacher'),
    ]);
    expect(status(), PushRegistrationStatus.registered);

    // A relaunch-style sync with the same user and token is a no-op.
    await controller().sync();
    expect(repository.registered, hasLength(1));
  });

  test('registers teacher web tokens with the web platform', () async {
    push.devicePlatform = NotificationPlatform.web;
    await start(app: NotificationApp.teacher);

    auth.signIn('teacher-1');
    await pumpEventQueue();

    expect(repository.registered.single, (
      token: 'token-1',
      platform: 'web',
      app: 'teacher',
    ));
  });

  test('waits for permission and never blocks sign-in', () async {
    push.status = NotificationPermissionStatus.denied;
    auth.userId = 'student-1';
    await start();
    await controller().sync();

    expect(status(), PushRegistrationStatus.permissionRequired);
    expect(repository.calls, isNot(contains('register')));

    // Granting from the profile card registers immediately.
    await container.read(notificationPermissionProvider.notifier).request();
    await pumpEventQueue();
    expect(repository.registered.single.token, 'token-1');
  });

  test('defers an ineligible account and retries later', () async {
    repository.registerFailures.add(
      const AppFailure(AppFailureType.notEligible),
    );
    auth.userId = 'student-1';
    await start();
    await controller().sync();
    expect(status(), PushRegistrationStatus.deferred);

    // Throttled right after the attempt.
    await controller().retryIfPending();
    expect(repository.registered, isEmpty);

    now = now.add(const Duration(minutes: 1));
    await controller().retryIfPending();
    expect(status(), PushRegistrationStatus.registered);
    expect(repository.registered, hasLength(1));
  });

  test(
    'a token refresh revokes the old token and registers the new one',
    () async {
      auth.userId = 'student-1';
      await start();
      await controller().sync();

      push.token = 'token-9';
      push.tokenRefresh.add('token-9');
      await pumpEventQueue();

      expect(repository.revoked, ['token-1']);
      expect(repository.registered.map((r) => r.token), ['token-1', 'token-9']);
    },
  );

  test(
    'sign-out revokes before the session ends, then retires the token',
    () async {
      auth.userId = 'student-1';
      await start();
      await controller().sync();

      await controller().prepareSignOut();
      expect(repository.revoked, ['token-1']);
      expect(push.deletedTokens, 1);

      // A refresh fired by deleteToken before sign-out completes must not
      // re-register the departing account.
      push.tokenRefresh.add(push.token!);
      await pumpEventQueue();
      expect(repository.registered, hasLength(1));

      await auth.signOut();
      await pumpEventQueue();
      expect(status(), PushRegistrationStatus.inactive);

      // The next account registers the fresh token.
      auth.signIn('student-2');
      await pumpEventQueue();
      expect(repository.registered.last.token, 'token-2');
    },
  );

  test('sign-out still completes when the revoke fails offline', () async {
    auth.userId = 'student-1';
    await start();
    await controller().sync();
    repository.revokeFailure = const AppFailure(AppFailureType.network);

    await controller().prepareSignOut();
    expect(push.deletedTokens, 1);
  });

  test('a token still owned by another account is rotated once', () async {
    repository.registerFailures.add(const AppFailure(AppFailureType.rejected));
    auth.userId = 'student-2';
    await start();
    await controller().sync();

    expect(push.deletedTokens, 1);
    expect(repository.registered.single.token, 'token-2');
    expect(status(), PushRegistrationStatus.registered);
  });

  test('switching users re-registers for the new account', () async {
    auth.userId = 'student-1';
    await start();
    await controller().sync();

    await auth.signOut();
    await pumpEventQueue();
    auth.signIn('student-2');
    await pumpEventQueue();

    expect(repository.registered, hasLength(2));
  });
}
