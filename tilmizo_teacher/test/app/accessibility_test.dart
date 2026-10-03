import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:tilmizo_teacher/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/create_group_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/group_details_screen.dart';
import 'package:tilmizo_teacher/features/profile/presentation/screens/complete_profile_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/groups_dashboard_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/widgets/group_card.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  void useLargeText(WidgetTester tester) {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testWidgets('login survives 2x text without overflow', (tester) async {
    useLargeText(tester);
    await pumpTeacherApp(tester, TestBackend());
    expect(find.byType(PhoneLoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard survives 2x text without overflow', (tester) async {
    useLargeText(tester);
    await pumpTeacherApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        groups: FakeGroupsRepository([
          buildGroup(name: 'مجموعة باسم طويل جدًا للصف الثالث الثانوي'),
        ]),
      ),
    );
    expect(find.byType(GroupsDashboardScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP, profile, and group forms survive 2x text', (tester) async {
    useLargeText(tester);
    final backend = TestBackend();
    await pumpTeacherApp(tester, backend);
    await tester.enterText(find.byType(TextField).first, '01012345678');
    await tester.pump();
    await tester.ensureVisible(find.byType(FilledButton).last);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(find.byType(OtpVerificationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    backend.profiles.profile = buildProfile(fullName: null);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pumpAndSettle();
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('group create and details survive 2x text', (tester) async {
    useLargeText(tester);
    await pumpTeacherApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        groups: FakeGroupsRepository([buildGroup()]),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GroupCard));
    await tester.pumpAndSettle();
    expect(find.byType(GroupDetailsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('إنشاء مجموعة'), 200);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء مجموعة'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateGroupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('interactive controls meet tap-target guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpTeacherApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        groups: FakeGroupsRepository([buildGroup()]),
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('wide screens center a constrained mobile layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpTeacherApp(tester, TestBackend());
    final width = tester.getSize(find.byType(PhoneLoginScreen)).width;
    expect(width, TelmizoSpacing.maxContentWidth);
  });
}
