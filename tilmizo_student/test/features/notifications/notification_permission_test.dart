import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/groups_home_screen.dart';

import '../../helpers/fake_notifications.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

TestBackend _backend(FakePushNotificationsService push) => TestBackend(
  auth: FakePhoneAuthService(signedIn: true),
  access: FakeGroupAccessRepository([approvedEntry()]),
  push: push,
);

Future<void> _openAccount(WidgetTester tester) async {
  await tester.tap(find.byTooltip('الحساب'));
  await tester.pumpAndSettle();
}

Future<void> _resume(WidgetTester tester) async {
  tester.binding
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
    ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
    ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
    ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initTestLocalization);
  setUp(initTestPreferences);

  testWidgets('the first signed-in start prompts once, not every launch', (
    tester,
  ) async {
    final push = FakePushNotificationsService(
      requestResult: NotificationPermissionStatus.denied,
    );
    final backend = _backend(push);
    await pumpStudentApp(tester, backend);
    expect(push.requests, 1);

    // Denied: the app and the notification center still work.
    expect(find.byType(GroupsHomeScreen), findsOneWidget);
    expect(backend.notifications.registered, isEmpty);

    // Relaunch with the same preferences.
    await tester.pumpWidget(const SizedBox());
    await pumpStudentApp(tester, _backend(push));
    expect(push.requests, 1);
  });

  testWidgets('no prompt before sign-in', (tester) async {
    final push = FakePushNotificationsService();
    await pumpStudentApp(tester, TestBackend(push: push));
    expect(push.requests, 0);
  });

  testWidgets('the account sheet can enable a denied permission', (
    tester,
  ) async {
    final push = FakePushNotificationsService(
      requestResult: NotificationPermissionStatus.denied,
    );
    final backend = _backend(push);
    await pumpStudentApp(tester, backend);
    await _openAccount(tester);
    expect(
      find.byKey(const Key('notification-permission-denied')),
      findsOneWidget,
    );

    push.requestResult = NotificationPermissionStatus.granted;
    await tester.tap(find.text('تفعيل الإشعارات'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('notification-permission-enabled')),
      findsOneWidget,
    );
    expect(backend.notifications.registered.single.app, 'student');
  });

  testWidgets('a blocked permission offers settings, then manual steps', (
    tester,
  ) async {
    final push = FakePushNotificationsService(
      status: NotificationPermissionStatus.blocked,
    )..settingsOpen = false;
    await pumpStudentApp(tester, _backend(push));
    expect(push.requests, 0);
    await _openAccount(tester);

    await tester.tap(find.text('فتح الإعدادات'));
    await tester.pumpAndSettle();

    expect(push.settingsOpened, 1);
    expect(find.textContaining('افتح إعدادات الجهاز'), findsOneWidget);
    expect(find.text('فتح الإعدادات'), findsNothing);
  });

  testWidgets('returning from settings rechecks and registers', (tester) async {
    final push = FakePushNotificationsService(
      status: NotificationPermissionStatus.blocked,
    );
    final backend = _backend(push);
    await pumpStudentApp(tester, backend);
    await _openAccount(tester);
    await tester.tap(find.text('فتح الإعدادات'));
    await tester.pumpAndSettle();

    push.status = NotificationPermissionStatus.granted;
    await _resume(tester);

    expect(
      find.byKey(const Key('notification-permission-enabled')),
      findsOneWidget,
    );
    expect(backend.notifications.registered, hasLength(1));
  });

  testWidgets('unsupported builds hide the permission card', (tester) async {
    await pumpStudentApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        access: FakeGroupAccessRepository([approvedEntry()]),
      ),
    );
    await _openAccount(tester);
    expect(find.text('الإشعارات غير مفعّلة'), findsNothing);
    expect(find.text('الإشعارات مفعّلة'), findsNothing);
  });
}
