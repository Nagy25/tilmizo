import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:tilmizo_teacher/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/empty_groups_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

FilledButton primaryButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton).last);

Finder get phoneField => find.byType(TextField).first;

Future<void> enterPhoneAndContinue(WidgetTester tester, String phone) async {
  await tester.enterText(phoneField, phone);
  await tester.pump();
  await tapContinue(tester);
}

Future<void> tapContinue(WidgetTester tester) async {
  await tester.ensureVisible(find.text('المتابعة برقم الموبايل'));
  await tester.tap(find.text('المتابعة برقم الموبايل'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initTestLocalization);

  group('phone login', () {
    testWidgets('continue is disabled until a number is typed', (tester) async {
      await pumpTeacherApp(tester, TestBackend());
      expect(primaryButton(tester).onPressed, isNull);

      await tester.enterText(phoneField, '010');
      await tester.pump();
      expect(primaryButton(tester).onPressed, isNotNull);
    });

    testWidgets('shows validation for a non-Egyptian number', (tester) async {
      final backend = TestBackend();
      await pumpTeacherApp(tester, backend);
      await enterPhoneAndContinue(tester, '01312345678');

      expect(
        find.text(
          'أدخل رقم موبايل مصري صحيح يبدأ بـ 010 أو 011 أو 012 أو 015.',
        ),
        findsOneWidget,
      );
      expect(backend.auth.requestedPhones, isEmpty);
    });

    testWidgets('marks a valid number and normalizes before Auth', (
      tester,
    ) async {
      final backend = TestBackend();
      await pumpTeacherApp(tester, backend);
      await tester.enterText(phoneField, '0101 234 5678');
      await tester.pump();
      expect(find.text('رقم صالح'), findsOneWidget);

      await tester.tap(find.text('المتابعة برقم الموبايل'));
      await tester.pumpAndSettle();
      expect(backend.auth.requestedPhones, [testPhone]);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    testWidgets('button is disabled while the request is pending', (
      tester,
    ) async {
      final backend = TestBackend();
      backend.auth.pendingRequest = Completer();
      await pumpTeacherApp(tester, backend);
      await tester.enterText(phoneField, '01012345678');
      await tester.pump();
      await tester.tap(find.text('المتابعة برقم الموبايل'));
      await tester.pump();

      expect(primaryButton(tester).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      backend.auth.pendingRequest!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows delivery and rate-limit failures', (tester) async {
      final backend = TestBackend();
      backend.auth.requestFailure = const AuthFailure(
        AuthFailureType.deliveryFailure,
      );
      await pumpTeacherApp(tester, backend);
      await enterPhoneAndContinue(tester, '01012345678');
      expect(find.textContaining('تعذّر بدء تسجيل الدخول'), findsOneWidget);

      backend.auth.requestFailure = const AuthFailure(
        AuthFailureType.rateLimited,
      );
      await tapContinue(tester);
      expect(find.textContaining('طلبات كثيرة'), findsOneWidget);
    });
  });

  group('OTP verification', () {
    Future<TestBackend> openOtp(WidgetTester tester) async {
      final backend = TestBackend();
      await pumpTeacherApp(tester, backend);
      await enterPhoneAndContinue(tester, '01012345678');
      return backend;
    }

    testWidgets('shows the masked number and a countdown', (tester) async {
      await openOtp(tester);
      expect(find.text('+20 10 •••• 5678'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      expect(find.textContaining('01012345678'), findsNothing);
    });

    testWidgets('verify requires six digits', (tester) async {
      final backend = await openOtp(tester);
      final codeField = find.byType(TextField).last;

      await tester.enterText(codeField, '12345');
      await tester.pump();
      expect(primaryButton(tester).onPressed, isNull);
      expect(find.text('تم إدخال 5 من 6'), findsOneWidget);

      await tester.enterText(codeField, '12a45');
      await tester.pump();
      expect(find.text('تم إدخال 4 من 6'), findsOneWidget);
      expect(backend.auth.verifications, isEmpty);
    });

    testWidgets('verification disables actions, then leaves auth screens', (
      tester,
    ) async {
      final backend = await openOtp(tester);
      backend.auth.pendingVerification = Completer();
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pump();

      expect(primaryButton(tester).onPressed, isNull);
      backend.auth.pendingVerification!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(EmptyGroupsScreen), findsOneWidget);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.byType(PhoneLoginScreen), findsNothing);
    });

    testWidgets('shows an invalid-code error', (tester) async {
      final backend = await openOtp(tester);
      backend.auth.verifyFailure = const AuthFailure(
        AuthFailureType.invalidOtp,
      );
      await tester.enterText(find.byType(TextField).last, '000000');
      await tester.pumpAndSettle();

      expect(find.text('رمز غير صحيح'), findsOneWidget);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
    });

    testWidgets('change number returns to login', (tester) async {
      await openOtp(tester);
      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();
      expect(find.byType(PhoneLoginScreen), findsOneWidget);
    });
  });
}
