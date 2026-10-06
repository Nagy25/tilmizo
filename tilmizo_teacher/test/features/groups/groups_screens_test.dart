import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/classes/presentation/screens/classes_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/create_group_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/empty_groups_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/edit_group_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/group_details_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/groups_dashboard_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      180,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(find.text(text).last);
  }
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void expectNoUnsupportedNavigation() {
  expect(find.byType(TabBar), findsNothing);
  expect(find.byType(BottomNavigationBar), findsNothing);
  expect(find.byType(NavigationBar), findsNothing);
  for (final word in ['طلاب', 'الطلاب', 'الحضور', 'امتحان', 'مدفوعات']) {
    expect(find.text(word), findsNothing);
  }
}

void main() {
  setUpAll(initTestLocalization);

  TestBackend backendWith(List groups) => TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    groups: FakeGroupsRepository([...groups]),
  );

  testWidgets('empty groups screen has no tabs and a create action', (
    tester,
  ) async {
    await pumpTeacherApp(tester, backendWith([]));

    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
    expectNoUnsupportedNavigation();
    expect(find.text('لا توجد مجموعات بعد'), findsOneWidget);
    expect(find.text('إنشاء مجموعة'), findsOneWidget);
  });

  testWidgets('dashboard shows groups without unsupported sections', (
    tester,
  ) async {
    await pumpTeacherApp(
      tester,
      backendWith([
        buildGroup(id: 'g1', name: 'مجموعة أ'),
        buildGroup(
          id: 'g2',
          name: 'مجموعة ب',
          isActive: false,
          inviteCode: null,
        ),
      ]),
    );

    expect(find.byType(GroupsDashboardScreen), findsOneWidget);
    expectNoUnsupportedNavigation();
    expect(find.text('مجموعة أ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('غير نشطة'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('غير نشطة'), findsOneWidget);
    expect(find.text('بدون كود انضمام'), findsOneWidget);
    expect(find.text('مجموعتان'), findsOneWidget);
    expect(find.text('الحصص'), findsOneWidget);
    expect(find.text('لا توجد حصص قادمة'), findsOneWidget);
    await tester.tap(find.text('الحصص'));
    await tester.pumpAndSettle();
    expect(find.byType(ClassesScreen), findsOneWidget);
  });

  testWidgets('create group requires a name and prefills the subject', (
    tester,
  ) async {
    final backend = backendWith([]);
    await pumpTeacherApp(tester, backend);
    await tapText(tester, 'إنشاء مجموعة');
    expect(find.byType(CreateGroupScreen), findsOneWidget);
    expect(find.text('الرياضيات'), findsWidgets);

    await tapText(tester, 'إنشاء المجموعة');
    expect(find.text('أدخل اسم المجموعة.'), findsOneWidget);
    expect(backend.groups.createdDrafts, isEmpty);
  });

  testWidgets('creating a group trims input and opens the dashboard', (
    tester,
  ) async {
    final backend = backendWith([]);
    await pumpTeacherApp(tester, backend);
    await tapText(tester, 'إنشاء مجموعة');
    await tester.enterText(find.byKey(const Key('group-name')), '  التفوق ');
    await tester.enterText(find.byKey(const Key('group-subject')), ' ');
    await tester.enterText(
      find.byKey(const Key('group-invite-code')),
      ' Ab-1 ',
    );
    await tapText(tester, 'إنشاء المجموعة');

    final draft = backend.groups.createdDrafts.single;
    expect(draft.name, 'التفوق');
    expect(draft.subject, isNull);
    expect(draft.grade, isNull);
    expect(draft.inviteCode, 'Ab-1');
    expect(draft.isActive, isTrue);
    expect(find.byType(GroupsDashboardScreen), findsOneWidget);
  });

  testWidgets('duplicate invite code is shown on the field', (tester) async {
    final backend = backendWith([buildGroup(inviteCode: 'TAKEN')]);
    await pumpTeacherApp(tester, backend);
    await tapText(tester, 'إنشاء مجموعة');
    await tester.enterText(find.byKey(const Key('group-name')), 'جديدة');
    await tester.enterText(find.byKey(const Key('group-invite-code')), 'TAKEN');
    await tapText(tester, 'إنشاء المجموعة');

    expect(
      find.text('كود الانضمام مستخدم بالفعل. اختر كودًا مختلفًا.'),
      findsOneWidget,
    );
    expect(find.byType(CreateGroupScreen), findsOneWidget);
  });

  testWidgets('create button is disabled while pending', (tester) async {
    final backend = backendWith([]);
    backend.groups.pendingMutation = Completer();
    await pumpTeacherApp(tester, backend);
    await tapText(tester, 'إنشاء مجموعة');
    await tester.enterText(find.byKey(const Key('group-name')), 'جديدة');
    await tester.ensureVisible(find.text('إنشاء المجموعة'));
    await tester.tap(find.text('إنشاء المجموعة'));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('إنشاء المجموعة'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    backend.groups.pendingMutation!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('details is read-only and edit opens its own screen', (
    tester,
  ) async {
    final backend = backendWith([buildGroup(id: 'g1')]);
    await pumpTeacherApp(tester, backend);
    await tester.tap(find.text('مجموعة التفوق'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupDetailsScreen), findsOneWidget);
    expect(find.text('شارك الكود مع طلابك'), findsOneWidget);
    expect(find.text('MATH-2025'), findsWidgets);
    expect(find.text('نسخ الكود'), findsOneWidget);
    expect(find.text('مشاركة الكود'), findsOneWidget);
    expect(find.text('الحصص'), findsOneWidget);
    expect(find.byKey(const Key('group-name')), findsNothing);

    await tester.tap(find.byKey(const Key('group-edit')));
    await tester.pumpAndSettle();
    expect(find.byType(EditGroupScreen), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('group-active')));
    await tester.tap(find.byKey(const Key('group-active')));
    await tapText(tester, 'حفظ التعديلات');
    expect(backend.groups.groups.single.isActive, isFalse);
    expect(find.byType(GroupDetailsScreen), findsOneWidget);
  });

  testWidgets('archive requires confirmation and retains history', (
    tester,
  ) async {
    final backend = backendWith([buildGroup(id: 'g1')]);
    await pumpTeacherApp(tester, backend);
    await tester.tap(find.text('مجموعة التفوق'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('group-edit')));
    await tester.pumpAndSettle();
    await tapText(tester, 'أرشفة المجموعة');
    expect(find.text('أرشفة المجموعة؟'), findsOneWidget);
    await tester.tap(find.text('أرشفة'));
    await tester.pumpAndSettle();

    expect(backend.groups.groups, hasLength(1));
    expect(backend.groups.groups.single.isActive, isFalse);
    expect(find.byType(GroupDetailsScreen), findsOneWidget);
  });

  testWidgets('canceling edit leaves the group unchanged', (tester) async {
    final backend = backendWith([buildGroup(id: 'g1')]);
    await pumpTeacherApp(tester, backend);
    await tester.tap(find.text('مجموعة التفوق'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('group-name')), 'اسم جديد');
    await tapText(tester, 'إلغاء التغييرات');

    expect(find.byType(GroupDetailsScreen), findsOneWidget);
    expect(backend.groups.groups.single.name, 'مجموعة التفوق');
  });

  testWidgets('a failed edit keeps the form open and group unchanged', (
    tester,
  ) async {
    final backend = backendWith([buildGroup(id: 'g1')]);
    backend.groups.mutationFailure = const AppFailure(AppFailureType.network);
    await pumpTeacherApp(tester, backend);
    await tester.tap(find.text('مجموعة التفوق'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('group-name')), 'اسم جديد');
    await tapText(tester, 'حفظ التعديلات');

    expect(find.byType(EditGroupScreen), findsOneWidget);
    expect(backend.groups.groups.single.name, 'مجموعة التفوق');
  });

  testWidgets('canceling archive keeps the group active', (tester) async {
    final backend = backendWith([buildGroup(id: 'g1')]);
    await pumpTeacherApp(tester, backend);
    await tester.tap(find.text('مجموعة التفوق'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group-edit')));
    await tester.pumpAndSettle();
    await tapText(tester, 'أرشفة المجموعة');
    await tester.tap(find.text('إلغاء').last);
    await tester.pumpAndSettle();

    expect(find.byType(EditGroupScreen), findsOneWidget);
    expect(backend.groups.groups.single.isActive, isTrue);
  });

  testWidgets('a failed archive stays on edit without changing the group', (
    tester,
  ) async {
    final backend = backendWith([buildGroup(id: 'g1')]);
    backend.groups.mutationFailure = const AppFailure(AppFailureType.network);
    await pumpTeacherApp(tester, backend);
    await tester.tap(find.text('مجموعة التفوق'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('group-edit')));
    await tester.pumpAndSettle();
    await tapText(tester, 'أرشفة المجموعة');
    await tester.tap(find.text('أرشفة'));
    await tester.pumpAndSettle();

    expect(find.byType(EditGroupScreen), findsOneWidget);
    expect(backend.groups.groups.single.isActive, isTrue);
  });

  testWidgets('a group deleted elsewhere shows an unavailable state', (
    tester,
  ) async {
    final backend = backendWith([buildGroup(id: 'g1')]);
    await pumpTeacherApp(tester, backend);
    backend.groups.groups.clear();
    await tester.tap(find.text('مجموعة التفوق'));
    await tester.pumpAndSettle();

    expect(find.text('المجموعة غير متاحة'), findsOneWidget);
    await tapText(tester, 'العودة للمجموعات');
    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
  });
}
