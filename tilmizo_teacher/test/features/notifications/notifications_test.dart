import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/app/my_app.dart';
import 'package:tilmizo_teacher/features/auth/presentation/controllers/app_flow_controller.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/empty_groups_screen.dart';
import 'package:tilmizo_teacher/features/notifications/presentation/controllers/home_permission_notice_controller.dart';
import 'package:tilmizo_teacher/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import '../../helpers/fake_notifications.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

const _session = '33333333-3333-4333-8333-333333333333';

TestBackend _backend({
  FakePushNotificationsService? push,
  bool groups = true,
}) => TestBackend(
  auth: FakePhoneAuthService(signedIn: true),
  groups: FakeGroupsRepository([if (groups) buildGroup()]),
  push: push,
);

StackRouter _router(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MyApp)))
        .read(appRouterProvider);

Finder get _bell => find.byKey(const Key('notifications-bell'));

void main() {
  setUpAll(initTestLocalization);
  setUp(initTestLocalization);

  test('home notice dismissal resets for the next session', () {
    final container = _backend().createContainer();
    expect(container.read(homePermissionNoticeDismissedProvider), isFalse);

    container.read(homePermissionNoticeDismissedProvider.notifier).dismiss();
    expect(container.read(homePermissionNoticeDismissedProvider), isTrue);

    container.read(resetSessionDataProvider)();
    expect(container.read(homePermissionNoticeDismissedProvider), isFalse);
  });

  testWidgets('the dashboard bell opens an empty teacher center', (
    tester,
  ) async {
    await pumpTeacherApp(tester, _backend());
    expect(
      find.bySemanticsLabel('الإشعارات، لا توجد إشعارات غير مقروءة'),
      findsOneWidget,
    );

    await tester.tap(_bell);
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('لا توجد إشعارات بعد'), findsOneWidget);
    expect(find.byKey(const Key('notifications-mark-all-read')), findsNothing);
  });

  testWidgets('the empty-groups home also shows the bell', (tester) async {
    await pumpTeacherApp(tester, _backend(groups: false));
    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
    expect(_bell, findsOneWidget);
  });

  testWidgets('unread rows are badged and open their re-read target', (
    tester,
  ) async {
    final backend = _backend();
    backend.notifications.notifications.add(
      buildNotification(
        id: 's',
        eventType: NotificationEventType.sessionRescheduled,
        targetId: _session,
        title: 'تم تغيير موعد الحصة',
      ),
    );
    backend.targets.visible[_session] = 'group-1';
    await pumpTeacherApp(tester, backend);
    expect(find.descendant(of: _bell, matching: find.text('1')), findsOne);

    await tester.tap(_bell);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تم تغيير موعد الحصة'));
    await tester.pumpAndSettle();

    expect(backend.notifications.calls, contains('markRead:s'));
    expect(_router(tester).current.name, SessionDetailsRoute.name);
  });

  testWidgets('registers the teacher device', (tester) async {
    final backend = _backend(
      push: FakePushNotificationsService(
        status: NotificationPermissionStatus.granted,
      ),
    );
    await pumpTeacherApp(tester, backend);

    expect(backend.notifications.registered, [
      (token: 'token-1', platform: 'android', app: 'teacher'),
    ]);
  });

  testWidgets('a teacher without groups is deferred, not blocked', (
    tester,
  ) async {
    final backend = _backend(
      groups: false,
      push: FakePushNotificationsService(
        status: NotificationPermissionStatus.granted,
      ),
    );
    backend.notifications.registerFailures.add(
      const AppFailure(AppFailureType.notEligible),
    );
    await pumpTeacherApp(tester, backend);

    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
    expect(backend.notifications.registered, isEmpty);
    expect(backend.notifications.calls, contains('register'));
  });

  testWidgets('the profile shows and fixes the permission state', (
    tester,
  ) async {
    final push = FakePushNotificationsService(
      requestResult: NotificationPermissionStatus.denied,
    );
    await pumpTeacherApp(tester, _backend(push: push));
    // The first-run prompt was answered with "deny".
    expect(push.requests, 1);

    await openRoute(tester, const EditProfileRoute());
    await tester.scrollUntilVisible(
      find.byKey(const Key('notification-permission-denied')),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    push.requestResult = NotificationPermissionStatus.granted;
    await tester.tap(find.text('تفعيل الإشعارات'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('notification-permission-enabled')),
      findsOneWidget,
    );
  });
}
