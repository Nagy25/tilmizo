import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/core/errors/app_failure.dart';
import 'package:tilmizo_teacher/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/empty_groups_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/groups_dashboard_screen.dart';
import 'package:tilmizo_teacher/features/profile/presentation/screens/complete_profile_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  testWidgets('no session opens login in Arabic RTL', (tester) async {
    await pumpTeacherApp(tester, TestBackend());

    expect(find.byType(PhoneLoginScreen), findsOneWidget);
    final direction = Directionality.of(
      tester.element(find.byType(PhoneLoginScreen)),
    );
    expect(direction, TextDirection.rtl);
    expect(find.text('المتابعة برقم الموبايل'), findsOneWidget);
  });

  testWidgets('incomplete profile cannot bypass completion', (tester) async {
    await pumpTeacherApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        profiles: FakeProfileRepository(buildProfile(teachingSubject: null)),
        groups: FakeGroupsRepository([buildGroup()]),
      ),
    );
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
    expect(find.byType(GroupsDashboardScreen), findsNothing);
  });

  testWidgets('complete profile without groups opens empty groups', (
    tester,
  ) async {
    await pumpTeacherApp(
      tester,
      TestBackend(auth: FakePhoneAuthService(signedIn: true)),
    );
    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
  });

  testWidgets('complete profile with groups opens the dashboard', (
    tester,
  ) async {
    await pumpTeacherApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        groups: FakeGroupsRepository([buildGroup()]),
      ),
    );
    expect(find.byType(GroupsDashboardScreen), findsOneWidget);
    expect(find.text('أهلًا بك، أحمد 👋'), findsOneWidget);
  });

  testWidgets('offline startup offers an Arabic retry', (tester) async {
    final backend = TestBackend(auth: FakePhoneAuthService(signedIn: true));
    backend.profiles.fetchFailure = const AppFailure(AppFailureType.network);
    await pumpTeacherApp(tester, backend);

    expect(find.text('تعذّر بدء التطبيق'), findsOneWidget);
    backend.profiles.fetchFailure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
  });

  testWidgets('session loss replaces the stack with login', (tester) async {
    final backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      groups: FakeGroupsRepository([buildGroup()]),
    );
    await pumpTeacherApp(tester, backend);
    backend.auth.emitAuthenticated();
    await tester.pumpAndSettle();

    backend.auth.expireSession();
    await tester.pumpAndSettle();
    expect(find.byType(PhoneLoginScreen), findsOneWidget);
    expect(find.byType(GroupsDashboardScreen), findsNothing);
  });
}
