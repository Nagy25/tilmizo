import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:tilmizo_student/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/empty_groups_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/groups_home_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/pending_request_screen.dart';
import 'package:tilmizo_student/features/profile/presentation/screens/complete_profile_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initTestLocalization);

  testWidgets('no session opens Arabic RTL login', (tester) async {
    await pumpStudentApp(tester, TestBackend());
    expect(find.byType(PhoneLoginScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(PhoneLoginScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('invalid phone shows validation and calls nothing', (
    tester,
  ) async {
    final backend = TestBackend();
    await pumpStudentApp(tester, backend);
    await tester.enterText(find.byType(TextField).first, '01312345678');
    await tester.pump();
    await tapText(tester, 'المتابعة برقم الموبايل');
    expect(find.textContaining('أدخل رقم موبايل مصري صحيح'), findsOneWidget);
    expect(backend.auth.requestedPhones, isEmpty);
  });

  testWidgets('login → OTP → profile completion → empty groups', (
    tester,
  ) async {
    final backend = TestBackend(
      profiles: FakeProfileRepository(buildProfile(fullName: null)),
    );
    await pumpStudentApp(tester, backend);

    await tester.enterText(find.byType(TextField).first, '011 0000 0000');
    await tester.pump();
    await tapText(tester, 'المتابعة برقم الموبايل');
    expect(backend.auth.requestedPhones, [testPhone]);
    expect(find.byType(OtpVerificationScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pumpAndSettle();
    expect(backend.auth.verifications.single, (
      phone: testPhone,
      code: '123456',
    ));
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
    expect(find.byType(OtpVerificationScreen), findsNothing);

    // Read-only verified phone, required name.
    final phone = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('verified-phone')),
        matching: find.byType(TextField),
      ),
    );
    expect(phone.readOnly, isTrue);
    await tapText(tester, 'حفظ ومتابعة');
    expect(find.text('أدخل اسمك بالكامل.'), findsOneWidget);
    expect(backend.profiles.updates, isEmpty);

    await tester.enterText(find.byKey(const Key('profile-name')), ' عمر ');
    await tapText(tester, 'حفظ ومتابعة');
    expect(backend.profiles.updates.single, ' عمر ');
    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('OTP verify button is disabled while verifying', (tester) async {
    final backend = TestBackend();
    backend.auth.pendingVerification = Completer();
    await pumpStudentApp(tester, backend);
    await tester.enterText(find.byType(TextField).first, '01100000000');
    await tester.pump();
    await tapText(tester, 'المتابعة برقم الموبايل');
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();

    final verify = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('تأكيد الرمز والمتابعة'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(verify.onPressed, isNull);
    backend.auth.pendingVerification!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a single pending group opens its status over the home', (
    tester,
  ) async {
    await pumpStudentApp(
      tester,
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        access: FakeGroupAccessRepository([buildEntry()]),
      ),
    );
    expect(find.byType(PendingRequestScreen), findsOneWidget);
    await tapText(tester, 'العودة إلى مجموعاتي');
    expect(find.byType(GroupsHomeScreen), findsOneWidget);
    expect(find.text('قيد مراجعة المعلم'), findsOneWidget);
  });

  testWidgets('session loss returns to login', (tester) async {
    final backend = TestBackend(auth: FakePhoneAuthService(signedIn: true));
    await pumpStudentApp(tester, backend);
    backend.auth.emitAuthenticated();
    await tester.pumpAndSettle();
    backend.auth.expireSession();
    await tester.pumpAndSettle();
    expect(find.byType(PhoneLoginScreen), findsOneWidget);
  });

  testWidgets('offline startup offers retry', (tester) async {
    final backend = TestBackend(auth: FakePhoneAuthService(signedIn: true));
    backend.access.overviewFailure = const AppFailure(AppFailureType.network);
    await pumpStudentApp(tester, backend);
    expect(find.text('تعذّر بدء التطبيق'), findsOneWidget);

    backend.access.overviewFailure = null;
    await tapText(tester, 'حاول مرة أخرى');
    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
  });
}
