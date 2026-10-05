import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/teacher_students/presentation/screens/all_students_screen.dart';
import 'package:tilmizo_teacher/features/teacher_students/domain/teacher_student.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/empty_groups_screen.dart';
import 'package:tilmizo_teacher/features/groups/presentation/screens/groups_dashboard_screen.dart';

import '../../helpers/fake_teacher_students.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  final students = [
    buildTeacherStudent(
      id: 's1',
      name: 'عمر أحمد',
      memberships: [
        TeacherStudentMembership(
          groupId: 'g1',
          groupName: 'الفيزياء',
          status: MembershipStatus.active,
          joinedAt: DateTime.utc(2026, 10, 1),
        ),
        TeacherStudentMembership(
          groupId: 'g2',
          groupName: 'الرياضيات',
          status: MembershipStatus.suspended,
          joinedAt: DateTime.utc(2026, 9, 1),
        ),
      ],
    ),
    buildTeacherStudent(
      id: 's2',
      name: 'سارة محمود',
      phone: '+201211112222',
      memberships: [
        TeacherStudentMembership(
          groupId: 'g2',
          groupName: 'الرياضيات',
          status: MembershipStatus.suspended,
          joinedAt: DateTime.utc(2026, 9, 2),
        ),
      ],
    ),
  ];

  TestBackend backend({List<TeacherStudent>? records, bool hasGroups = true}) =>
      TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        groups: FakeGroupsRepository(hasGroups ? [buildGroup(id: 'g1')] : []),
        teacherStudents: FakeTeacherStudentsRepository(records ?? students),
      );

  Future<void> openList(WidgetTester tester, TestBackend app) async {
    await pumpTeacherApp(tester, app);
    await tester.scrollUntilVisible(
      find.byKey(const Key('all-students-tile')),
      220,
    );
    await tester.tap(find.byKey(const Key('all-students-tile')));
    await tester.pumpAndSettle();
    expect(find.byType(AllStudentsScreen), findsOneWidget);
  }

  testWidgets('home tile opens a deduplicated read-only list', (tester) async {
    useTallViewport(tester);
    final app = backend();
    await pumpTeacherApp(tester, app);
    expect(find.byType(GroupsDashboardScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('all-students-tile')),
      220,
    );
    expect(find.text('عدد الطلاب: 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('all-students-tile')));
    await tester.pumpAndSettle();

    expect(find.byType(AllStudentsScreen), findsOneWidget);
    expect(find.text('طلاب في أكثر من مجموعة: 1'), findsOneWidget);
    expect(find.text('عمر أحمد'), findsOneWidget);
    expect(find.text('سارة محمود'), findsOneWidget);
    await tester.tap(find.text('عمر أحمد'));
    await tester.pumpAndSettle();
    expect(find.byType(AllStudentsScreen), findsOneWidget);
    expect(
      find.ancestor(of: find.text('عمر أحمد'), matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('search and status/group filters narrow the same list', (
    tester,
  ) async {
    useTallViewport(tester);
    await openList(tester, backend());
    await tester.enterText(
      find.byKey(const Key('all-students-search')),
      'سارة',
    );
    await tester.pumpAndSettle();
    expect(find.text('عمر أحمد'), findsNothing);
    expect(find.text('سارة محمود'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('all-students-search')), '');
    await tester.tap(find.text('موقوف').first);
    await tester.pumpAndSettle();
    expect(find.text('عمر أحمد'), findsOneWidget);
    expect(find.text('سارة محمود'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الفيزياء').last);
    await tester.pumpAndSettle();
    expect(find.text('عمر أحمد'), findsNothing);
    expect(find.text('سارة محمود'), findsNothing);
    expect(
      find.text('لم نجد طلابًا مطابقين للبحث أو التصفية.'),
      findsOneWidget,
    );
  });

  testWidgets('empty-group home still opens an empty list', (tester) async {
    final app = backend(records: [], hasGroups: false);
    await pumpTeacherApp(tester, app);
    expect(find.byType(EmptyGroupsScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('all-students-tile')),
      220,
    );
    await tester.tap(find.byKey(const Key('all-students-tile')));
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد طلاب في مجموعاتك بعد.'), findsOneWidget);
  });

  testWidgets('load error shows neutral count and retry', (tester) async {
    useTallViewport(tester);
    final app = backend();
    app.teacherStudents.fetchFailure = const AppFailure(AppFailureType.network);
    await pumpTeacherApp(tester, app);
    await tester.scrollUntilVisible(
      find.byKey(const Key('all-students-tile')),
      220,
    );
    expect(find.text('عدد الطلاب: —'), findsOneWidget);
    await tester.tap(find.byKey(const Key('all-students-tile')));
    await tester.pumpAndSettle();
    expect(find.text('تعذّر تحميل الطلاب'), findsOneWidget);
    app.teacherStudents.fetchFailure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.text('عمر أحمد'), findsOneWidget);
  });
}
