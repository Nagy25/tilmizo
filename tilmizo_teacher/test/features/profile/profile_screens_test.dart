import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/empty_groups_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/groups_dashboard_screen.dart';
import 'package:tilmizo_teacher/features/profile/domain/profile_update.dart';
import 'package:tilmizo_teacher/features/profile/presentation/screens/edit_profile_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

TestBackend incompleteBackend() => TestBackend(
  auth: FakePhoneAuthService(signedIn: true),
  profiles: FakeProfileRepository(
    buildProfile(fullName: null, teachingSubject: null),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  testWidgets('verified phone is shown read-only', (tester) async {
    await pumpTeacherApp(tester, incompleteBackend());

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('verified-phone')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.readOnly, isTrue);
    expect(find.text('010 1234 5678'), findsOneWidget);
    expect(find.text('موثّق بواسطة Supabase'), findsOneWidget);
  });

  testWidgets('name and specialization are required', (tester) async {
    final backend = incompleteBackend();
    await pumpTeacherApp(tester, backend);
    await tapText(tester, 'حفظ ومتابعة');

    expect(find.text('أدخل اسمك بالكامل.'), findsOneWidget);
    expect(find.text('أدخل تخصصك أو المادة التي تدرّسها.'), findsOneWidget);
    expect(backend.profiles.updates, isEmpty);
  });

  testWidgets('completion saves permitted fields and continues', (
    tester,
  ) async {
    final backend = incompleteBackend();
    await pumpTeacherApp(tester, backend);
    await tester.enterText(find.byKey(const Key('profile-name')), ' أحمد ');
    await tapText(tester, 'الفيزياء');
    await tapText(tester, 'حفظ ومتابعة');

    expect(
      backend.profiles.updates.single,
      ProfileUpdate.tryCreate(fullName: 'أحمد', teachingSubject: 'الفيزياء'),
    );
    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
  });

  testWidgets('save is disabled while pending', (tester) async {
    final backend = incompleteBackend();
    backend.profiles.pendingUpdate = Completer();
    await pumpTeacherApp(tester, backend);
    await tester.enterText(find.byKey(const Key('profile-name')), 'أحمد');
    await tester.enterText(find.byKey(const Key('profile-subject')), 'علوم');
    await tester.ensureVisible(find.text('حفظ ومتابعة'));
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('حفظ ومتابعة'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    backend.profiles.pendingUpdate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('edit profile logs out through Auth', (tester) async {
    final backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      groups: FakeGroupsRepository([buildGroup()]),
    );
    await pumpTeacherApp(tester, backend);
    expect(find.byType(GroupsDashboardScreen), findsOneWidget);

    await tester.tap(find.byTooltip('الملف الشخصي'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);

    await tapText(tester, 'تسجيل الخروج');
    await tester.tap(find.text('تسجيل الخروج').last);
    await tester.pumpAndSettle();

    expect(backend.auth.signOutCount, 1);
    expect(find.byType(PhoneLoginScreen), findsOneWidget);
  });
}
