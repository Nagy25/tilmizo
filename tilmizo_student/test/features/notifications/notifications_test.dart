import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/app/my_app.dart';
import 'package:tilmizo_student/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:tilmizo_student/router/app_router.dart';

import '../../helpers/fake_notifications.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

const _session = '33333333-3333-4333-8333-333333333333';

TestBackend _backend({
  List<AppNotification> notifications = const [],
  FakePushNotificationsService? push,
}) {
  final backend = TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    access: FakeGroupAccessRepository([approvedEntry()]),
    push: push,
  );
  backend.notifications.notifications.addAll(notifications);
  return backend;
}

StackRouter _router(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MyApp)))
        .read(appRouterProvider);

Finder get _bell => find.byKey(const Key('notifications-bell'));

Future<void> _openCenter(WidgetTester tester) async {
  await tester.tap(_bell);
  await tester.pumpAndSettle();
  expect(find.byType(NotificationsScreen), findsOneWidget);
}

void main() {
  setUpAll(initTestLocalization);
  setUp(initTestPreferences);

  final payment = buildNotification(
    id: 'pay',
    eventType: NotificationEventType.paymentChargeNew,
    title: 'مبلغ جديد مستحق',
    body: 'اشتراك أكتوبر',
    createdAt: DateTime.utc(2026, 10, 1, 10),
  );
  final session = buildNotification(
    id: 'ses',
    eventType: NotificationEventType.sessionCancelled,
    targetId: _session,
    title: 'تم إلغاء الحصة',
    createdAt: DateTime.utc(2026, 10, 1, 9),
  );
  final read = buildNotification(
    id: 'old',
    title: 'واجب جديد',
    createdAt: DateTime.utc(2026, 9, 20),
    readAt: DateTime.utc(2026, 9, 21),
  );

  testWidgets('the bell shows the unread count and opens the center', (
    tester,
  ) async {
    final backend = _backend(notifications: [read, session, payment]);
    await pumpStudentApp(tester, backend);

    expect(
      find.descendant(of: _bell, matching: find.text('2')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('الإشعارات، إشعاران غير مقروءين'),
      findsOneWidget,
    );

    await _openCenter(tester);
    // Newest first.
    final titles = tester
        .widgetList<NotificationTile>(find.byType(NotificationTile))
        .map((tile) => tile.notification.id);
    expect(titles, ['pay', 'ses', 'old']);
    expect(find.text('اشتراك أكتوبر'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notifications-mark-all-read')));
    await tester.pumpAndSettle();
    expect(backend.notifications.calls, contains('markAllRead'));
    expect(find.byKey(const Key('notifications-mark-all-read')), findsNothing);

    await _router(tester).maybePop();
    await tester.pumpAndSettle();
    expect(find.descendant(of: _bell, matching: find.text('2')), findsNothing);
  });

  testWidgets('one notification can be marked read without opening it', (
    tester,
  ) async {
    final backend = _backend(notifications: [payment]);
    await pumpStudentApp(tester, backend);
    await _openCenter(tester);

    await tester.tap(find.byTooltip('تحديد كمقروء'));
    await tester.pumpAndSettle();

    expect(backend.notifications.calls, contains('markRead:pay'));
    expect(find.byTooltip('تحديد كمقروء'), findsNothing);
    expect(find.byType(NotificationsScreen), findsOneWidget);
  });

  testWidgets('tapping a notification marks it read and opens its target', (
    tester,
  ) async {
    final backend = _backend(notifications: [payment]);
    backend.targets.visible[uuidA] = 'group-1';
    await pumpStudentApp(tester, backend);
    await _openCenter(tester);

    await tester.tap(find.text('مبلغ جديد مستحق'));
    await tester.pumpAndSettle();

    expect(backend.notifications.calls, contains('markRead:pay'));
    expect(_router(tester).current.name, PaymentHistoryRoute.name);
  });

  testWidgets('a target the student can no longer read is not opened', (
    tester,
  ) async {
    final backend = _backend(notifications: [session]);
    await pumpStudentApp(tester, backend);
    await _openCenter(tester);

    await tester.tap(find.text('تم إلغاء الحصة'));
    await tester.pumpAndSettle();

    expect(find.text('هذا المحتوى لم يعد متاحًا لك.'), findsOneWidget);
    expect(_router(tester).current.name, NotificationsRoute.name);
  });

  testWidgets('empty and error states', (tester) async {
    final backend = _backend();
    backend.notifications.fetchFailure = const AppFailure(
      AppFailureType.network,
    );
    await pumpStudentApp(tester, backend);
    await _openCenter(tester);
    expect(find.text('تعذّر تحميل الإشعارات'), findsOneWidget);

    backend.notifications.fetchFailure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد إشعارات بعد'), findsOneWidget);
  });

  group('push', () {
    FakePushNotificationsService granted() => FakePushNotificationsService(
      status: NotificationPermissionStatus.granted,
    );

    testWidgets('registers the student device after sign-in', (tester) async {
      final backend = _backend(push: granted());
      await pumpStudentApp(tester, backend);

      expect(backend.notifications.registered, [
        (token: 'token-1', platform: 'android', app: 'student'),
      ]);
    });

    testWidgets('a background tap opens the re-read destination', (
      tester,
    ) async {
      final push = granted();
      final backend = _backend(push: push);
      backend.targets.visible[_session] = 'group-1';
      await pumpStudentApp(tester, backend);

      push.opened.add(
        const NotificationTarget(
          eventType: NotificationEventType.sessionRescheduled,
          targetId: _session,
        ),
      );
      await tester.pumpAndSettle();

      expect(_router(tester).current.name, StudentSessionDetailsRoute.name);
    });

    testWidgets('an unresolvable tap opens the notification center', (
      tester,
    ) async {
      final push = granted();
      await pumpStudentApp(tester, _backend(push: push));

      push.opened.add(NotificationTarget.fromPushData({'event_type': 'x'}));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('a launch tap waits until startup reaches home', (
      tester,
    ) async {
      final push = granted()
        ..launchTarget = const NotificationTarget(
          eventType: NotificationEventType.paymentOverdue,
          targetId: uuidB,
        );
      final backend = _backend(push: push);
      backend.targets.visible[uuidB] = 'group-1';
      await pumpStudentApp(tester, backend);

      expect(_router(tester).current.name, PaymentHistoryRoute.name);
      expect(_router(tester).stackData.first.name, GroupsHomeRoute.name);
    });

    testWidgets('a foreground message refreshes the badge in-app', (
      tester,
    ) async {
      final push = granted();
      final backend = _backend(push: push);
      await pumpStudentApp(tester, backend);
      expect(
        find.descendant(of: _bell, matching: find.text('1')),
        findsNothing,
      );

      backend.notifications.notifications.add(payment);
      push.foreground.add(payment.target);
      await tester.pumpAndSettle();

      expect(find.descendant(of: _bell, matching: find.text('1')), findsOne);
      expect(find.text('وصلك إشعار جديد'), findsOneWidget);
    });
  });
}
