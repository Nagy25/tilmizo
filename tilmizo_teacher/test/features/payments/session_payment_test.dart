import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/classes/domain/class_session.dart';
import 'package:tilmizo_teacher/features/classes/presentation/screens/session_details_screen.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import '../../helpers/fake_classes.dart';
import '../../helpers/fake_payments.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  TestBackend backendWith({List<ClassSession>? sessions}) => TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    now: testTime,
    groups: FakeGroupsRepository([buildGroup(id: 'group-1')]),
    classes: FakeClassesRepository(sessions: sessions),
  );

  /// Fills the date (today) and a 17:00–18:00 time range.
  Future<void> fillSessionTime(WidgetTester tester) async {
    await tapVisible(tester, find.byKey(const Key('session-date-field')));
    await tester.tap(find.text('حسنًا'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byIcon(Icons.play_circle_outline));
    await tester.tap(find.text('حسنًا'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byIcon(Icons.stop_circle_outlined));
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final dialog = find.byType(Dialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)).first,
      '6',
    );
    await tester.tap(find.text('حسنًا'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('location-place-field')),
      'سنتر الأوائل',
    );
  }

  Future<void> openSessionForm(WidgetTester tester, TestBackend backend) async {
    useTallPhone(tester);
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, OneTimeSessionRoute(groupId: 'group-1'));
    await fillSessionTime(tester);
  }

  testWidgets('a session without an amount keeps the no-payment flow', (
    tester,
  ) async {
    final backend = backendWith();
    await openSessionForm(tester, backend);
    await tapVisible(tester, find.byKey(const Key('create-one-time-session')));

    final draft = backend.classes.createdDrafts.single;
    expect(draft.paymentAmount, isNull);
    expect(find.byType(SessionDetailsScreen), findsOneWidget);
  });

  testWidgets('a session amount is sent with the new session', (tester) async {
    final backend = backendWith();
    await openSessionForm(tester, backend);

    final amount = find.byKey(const Key('session-payment-amount'));
    await tester.enterText(amount, '12.345');
    await tapVisible(tester, find.byKey(const Key('create-one-time-session')));
    expect(find.text('استخدم رقمين عشريين على الأكثر.'), findsOneWidget);
    expect(backend.classes.createdDrafts, isEmpty);

    await tester.enterText(amount, '120.5');
    await tapVisible(tester, find.byKey(const Key('create-one-time-session')));
    expect(backend.classes.createdDrafts.single.paymentAmount, egp(120.5));
  });

  testWidgets('session details attach an amount once', (tester) async {
    final backend = backendWith(sessions: [buildSession()]);
    useTallPhone(tester);
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, SessionDetailsRoute(sessionId: 'session-1'));
    expect(find.text('لا يوجد مبلغ لهذه الحصة.'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('attach-session-payment')));
    await tester.enterText(find.byKey(const Key('payment-amount-field')), '90');
    await tester.tap(find.byKey(const Key('confirm-attach-session-payment')));
    await tester.pumpAndSettle();

    expect(backend.payments.calls, ['attach:session-1:90']);
    expect(find.text('90 ج.م لكل طالب'), findsOneWidget);
    expect(find.byKey(const Key('attach-session-payment')), findsNothing);
  });

  testWidgets('no attach action for suspended groups or cancelled sessions', (
    tester,
  ) async {
    final backend = backendWith(
      sessions: [
        buildSession(id: 'cancelled', status: SessionStatus.cancelled),
        buildSession(id: 'paused', groupSuspended: true),
        buildSession(id: 'paid'),
      ],
    );
    backend.payments.sessionAmounts['paid'] = egp(40);
    useTallPhone(tester);
    await pumpTeacherApp(tester, backend);

    await openRoute(tester, SessionDetailsRoute(sessionId: 'cancelled'));
    expect(find.byKey(const Key('attach-session-payment')), findsNothing);

    await openRoute(tester, SessionDetailsRoute(sessionId: 'paused'));
    expect(find.text('لا يوجد مبلغ لهذه الحصة.'), findsOneWidget);
    expect(find.byKey(const Key('attach-session-payment')), findsNothing);

    await openRoute(tester, SessionDetailsRoute(sessionId: 'paid'));
    expect(find.text('40 ج.م لكل طالب'), findsOneWidget);
    expect(find.byKey(const Key('attach-session-payment')), findsNothing);
  });
}
