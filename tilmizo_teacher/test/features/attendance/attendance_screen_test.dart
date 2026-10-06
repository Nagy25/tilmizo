import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:tilmizo_teacher/features/classes/domain/class_session.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import '../../helpers/fake_classes.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  TestBackend backendWith({required ClassSession session}) => TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    now: testTime,
    groups: FakeGroupsRepository([buildGroup(id: 'group-1')]),
    classes: FakeClassesRepository(sessions: [session]),
    attendance: FakeAttendanceRepository(
      current: [
        buildStudent('1', name: 'أحمد'),
        buildStudent('2', name: 'بسمة', saved: AttendanceStatus.late),
        buildStudent('3', name: 'جميلة'),
      ],
      former: [buildStudent('9', name: 'زياد', saved: AttendanceStatus.absent)],
    ),
  );

  Future<void> mark(WidgetTester tester, String id, AttendanceStatus status) =>
      tapVisible(tester, find.byKey(Key('mark-$id-${status.backendValue}')));

  testWidgets('quick mode saves only explicit marks', (tester) async {
    useTallPhone(tester);
    final backend = backendWith(session: buildSession());
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, AttendanceRoute(sessionId: 'session-1'));

    expect(find.text('الطالب غير المسجَّل لا يُحسب غائبًا.'), findsOneWidget);
    expect(find.text('طلاب سابقون في المجموعة'), findsOneWidget);
    expect(find.text('زياد'), findsOneWidget);
    // Quick mode offers present and absent only.
    expect(find.byKey(const Key('mark-1-late')), findsNothing);

    await mark(tester, '1', AttendanceStatus.present);
    await mark(tester, '9', AttendanceStatus.present);
    expect(find.text('حفظ الحضور (2)'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('save-attendance')));
    expect(backend.attendance.writes, [
      (studentId: '1', status: AttendanceStatus.present),
      (studentId: '9', status: AttendanceStatus.present),
    ]);
    expect(find.text('تم حفظ الحضور.'), findsOneWidget);
    expect(find.text('حفظ الحضور (0)'), findsOneWidget);
  });

  testWidgets('detailed mode offers all five marks and reports failures', (
    tester,
  ) async {
    useTallPhone(tester);
    final backend = backendWith(session: buildSession());
    backend.attendance.failingStudents.add('3');
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, AttendanceRoute(sessionId: 'session-1'));

    await tapVisible(tester, find.text('تفصيلي'));
    for (final status in AttendanceStatus.values) {
      expect(find.byKey(Key('mark-1-${status.backendValue}')), findsOneWidget);
    }
    await mark(tester, '1', AttendanceStatus.excused);
    await mark(tester, '3', AttendanceStatus.late);
    await tapVisible(tester, find.byKey(const Key('save-attendance')));

    expect(find.textContaining('تم حفظ 1 وتعذّر حفظ 1'), findsOneWidget);
    expect(find.text('لم يُحفظ'), findsOneWidget);
    expect(find.text('حفظ الحضور (1)'), findsOneWidget);
  });

  testWidgets('bulk present fills only unmarked students', (tester) async {
    useTallPhone(tester);
    final backend = backendWith(session: buildSession());
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, AttendanceRoute(sessionId: 'session-1'));

    await tapVisible(tester, find.byKey(const Key('mark-unmarked-present')));
    await tapVisible(tester, find.byKey(const Key('save-attendance')));
    expect(backend.attendance.writes, [
      (studentId: '1', status: AttendanceStatus.present),
      (studentId: '3', status: AttendanceStatus.present),
    ]);
  });

  testWidgets('attendance is read-only before the session day', (tester) async {
    useTallPhone(tester);
    await pumpTeacherApp(
      tester,
      backendWith(session: buildSession(startsAt: DateTime.utc(2026, 10, 3))),
    );
    await openRoute(tester, AttendanceRoute(sessionId: 'session-1'));

    expect(
      find.textContaining('يُفتح تسجيل الحضور في يوم الحصة'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('save-attendance')), findsNothing);
    expect(find.byKey(const Key('mark-1-present')), findsNothing);
    expect(find.text('متأخر'), findsWidgets);
  });

  testWidgets('cancelled sessions only show saved history', (tester) async {
    useTallPhone(tester);
    await pumpTeacherApp(
      tester,
      backendWith(session: buildSession(status: SessionStatus.cancelled)),
    );
    await openRoute(tester, AttendanceRoute(sessionId: 'session-1'));

    expect(find.text('الحصة ملغاة، لذا يمكن عرض الحضور فقط.'), findsOneWidget);
    expect(find.byKey(const Key('save-attendance')), findsNothing);
  });

  testWidgets('leaving with unsaved marks asks for confirmation', (
    tester,
  ) async {
    useTallPhone(tester);
    final backend = backendWith(session: buildSession());
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, AttendanceRoute(sessionId: 'session-1'));
    await mark(tester, '1', AttendanceStatus.absent);

    await tester.tap(find.byTooltip('رجوع').first);
    await tester.pumpAndSettle();
    expect(find.text('تجاهل التغييرات؟'), findsOneWidget);
    await tester.tap(find.byKey(const Key('discard-attendance')));
    await tester.pumpAndSettle();
    expect(find.text('تجاهل التغييرات؟'), findsNothing);
    expect(find.byType(AttendanceScreen), findsNothing);
    expect(backend.attendance.writes, isEmpty);
  });
}
