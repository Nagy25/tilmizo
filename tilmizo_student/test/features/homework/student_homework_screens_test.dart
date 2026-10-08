import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/app/my_app.dart';
import 'package:tilmizo_student/features/group_access/domain/approved_group.dart';
import 'package:tilmizo_student/features/homework/presentation/screens/student_homework_details_screen.dart';
import 'package:tilmizo_student/features/student_classes/domain/student_class.dart';
import 'package:tilmizo_student/router/app_router.dart';

import '../../helpers/fake_homework.dart';
import '../../helpers/fake_resources.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

/// Wednesday 2026-10-08 12:00 in Cairo (UTC+3).
final _now = DateTime.utc(2026, 10, 8, 9);

TestBackend _backend({DateTime? now}) {
  final backend = TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    access: FakeGroupAccessRepository([approvedEntry()]),
    now: now ?? _now,
  );
  backend.access.approvedGroups['group-1'] = const ApprovedGroup(
    id: 'group-1',
    name: 'مجموعة العباقرة',
  );
  return backend;
}

Future<void> _push(WidgetTester tester, PageRouteInfo route) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MyApp)),
  );
  unawaited(container.read(appRouterProvider).push(route));
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, TestBackend backend) async {
  await pumpStudentApp(tester, backend);
  await _push(tester, ApprovedGroupRoute(groupId: 'group-1'));
  await tester.tap(find.byKey(const Key('group-tab-homework')));
  await tester.pumpAndSettle();
}

Future<void> _openDetails(
  WidgetTester tester,
  TestBackend backend, {
  String id = 'hw-1',
}) async {
  await pumpStudentApp(tester, backend);
  await _push(
    tester,
    StudentHomeworkDetailsRoute(groupId: 'group-1', homeworkId: id),
  );
  expect(find.byType(StudentHomeworkDetailsScreen), findsOneWidget);
}

Future<void> _saveLink(WidgetTester tester, String url) async {
  await tester.enterText(find.byKey(const Key('homework-link-field')), url);
  await tester.ensureVisible(find.byKey(const Key('homework-link-save')));
  await tester.tap(find.byKey(const Key('homework-link-save')));
  await tester.pumpAndSettle();
}

HomeworkLinkSubmission _saved(String url) => HomeworkLinkSubmission(
  homeworkId: 'hw-1',
  studentId: testUserId,
  url: url,
  createdAt: DateTime.utc(2026, 10, 6),
  updatedAt: DateTime.utc(2026, 10, 6),
);

const _forbidden = ['قيد الانتظار', 'مكتمل', 'تم التسليم', 'الدرجة', 'رفع ملف'];

void main() {
  setUpAll(initTestLocalization);

  testWidgets('homework tab sits after Classes and keeps Announcements', (
    tester,
  ) async {
    final backend = _backend()
      ..homework.homework.addAll([
        buildHomework(),
        buildHomework(
          id: 'hw-2',
          instructions: null,
          type: HomeworkSubmissionType.manual,
          resourceIds: ['r1'],
          createdAt: DateTime.utc(2026, 10, 6),
        ),
      ]);
    await _openTab(tester, backend);

    final classes = tester.getCenter(
      find.byKey(const Key('group-tab-classes')),
    );
    final homework = tester.getCenter(
      find.byKey(const Key('group-tab-homework')),
    );
    final announcements = tester.getCenter(
      find.byKey(const Key('group-tab-announcements')),
    );
    // RTL: later tabs sit further left.
    expect(homework.dx, lessThan(classes.dx));
    expect(announcements.dx, lessThan(homework.dx));

    expect(find.textContaining('واجب حصة'), findsNWidgets(2));
    expect(find.text('حل تمارين صفحة 42'), findsOneWidget);
    expect(find.text('ملفات مرفقة بدون تعليمات'), findsOneWidget);
    expect(find.text('ملف مرفق'), findsOneWidget);
    for (final text in _forbidden) {
      expect(find.text(text), findsNothing);
    }

    await tester.tap(find.byKey(const Key('student-homework-hw-1')));
    await tester.pumpAndSettle();
    expect(find.byType(StudentHomeworkDetailsScreen), findsOneWidget);
  });

  testWidgets('empty and error states with retry', (tester) async {
    final backend = _backend();
    await _openTab(tester, backend);
    expect(find.byKey(const Key('student-homework-empty')), findsOneWidget);

    backend.homework
      ..homework.add(buildHomework())
      ..failure = const AppFailure(AppFailureType.network);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student-homework-error')), findsOneWidget);

    backend.homework.failure = null;
    await tester.tap(find.text('حاول مرة أخرى').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student-homework-hw-1')), findsOneWidget);
  });

  testWidgets('the session page opens the same details screen', (tester) async {
    final backend = _backend()..homework.homework.add(buildHomework());
    final start = DateTime.utc(2026, 10, 5, 14);
    backend.classes.sessions.add(
      StudentClassSession(
        id: 'session-1',
        groupId: 'group-1',
        groupName: 'مجموعة العباقرة',
        startsAt: start,
        endsAt: start.add(const Duration(hours: 2)),
        locationType: SessionLocationType.physical,
        physicalLocation: 'سنتر الأوائل',
        status: SessionStatus.completed,
        attendance: AttendanceStatus.present,
      ),
    );
    await pumpStudentApp(tester, backend);
    await _push(tester, StudentSessionDetailsRoute(sessionId: 'session-1'));

    final card = find.byKey(const Key('student-homework-hw-1'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(StudentHomeworkDetailsScreen), findsOneWidget);
    expect(find.text('حل تمارين صفحة 42'), findsOneWidget);
  });

  testWidgets('manual homework says what to bring with no action', (
    tester,
  ) async {
    final backend = _backend()
      ..homework.homework.add(
        buildHomework(type: HomeworkSubmissionType.manual),
      );
    await _openDetails(tester, backend);
    expect(find.byKey(const Key('homework-manual-note')), findsOneWidget);
    expect(find.byKey(const Key('homework-link-section')), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    for (final text in _forbidden) {
      expect(find.text(text), findsNothing);
    }
  });

  testWidgets('none-type homework shows content only', (tester) async {
    final backend = _backend()
      ..homework.homework.add(buildHomework(type: HomeworkSubmissionType.none));
    await _openDetails(tester, backend);
    expect(find.byKey(const Key('homework-none-note')), findsOneWidget);
    expect(find.byKey(const Key('homework-link-section')), findsNothing);
    expect(find.text('حل تمارين صفحة 42'), findsOneWidget);
  });

  testWidgets('saves a first link, then replaces it', (tester) async {
    final backend = _backend()
      ..homework.homework.add(
        buildHomework(dueDate: DateTime.utc(2026, 10, 10)),
      );
    await _openDetails(tester, backend);

    expect(find.text('لم ترسل رابطًا.'), findsOneWidget);
    await _saveLink(tester, 'drive.example.com');
    expect(find.text('أدخل رابطًا صحيحًا يبدأ بـ https://'), findsOneWidget);
    expect(backend.homework.submitCalls, isEmpty);

    await _saveLink(tester, 'https://drive.example.com/v1');
    expect(backend.homework.submitCalls.single, (
      'hw-1',
      'https://drive.example.com/v1',
    ));
    expect(find.text('تم حفظ الرابط.'), findsOneWidget);
    expect(find.text('https://drive.example.com/v1'), findsOneWidget);
    expect(find.byKey(const Key('homework-link-field')), findsNothing);

    await tester.tap(find.byKey(const Key('homework-link-edit')));
    await tester.pumpAndSettle();
    await _saveLink(tester, 'https://drive.example.com/v2');
    expect(backend.homework.submitCalls, hasLength(2));
    expect(find.text('https://drive.example.com/v2'), findsOneWidget);
    expect(find.text('https://drive.example.com/v1'), findsNothing);
  });

  testWidgets('without a due date editing stays available', (tester) async {
    final backend = _backend(now: DateTime.utc(2030))
      ..homework.homework.add(buildHomework())
      ..homework.submissions['hw-1'] = _saved('https://a.example.com');
    backend.homework.serverNow = () => DateTime.utc(2030);
    await _openDetails(tester, backend);

    expect(find.byKey(const Key('homework-link-closed')), findsNothing);
    await tester.tap(find.byKey(const Key('homework-link-edit')));
    await tester.pumpAndSettle();
    await _saveLink(tester, 'https://b.example.com');
    expect(find.text('https://b.example.com'), findsOneWidget);
  });

  group('Cairo due-date boundary', () {
    final due = DateTime.utc(2026, 10, 10);

    testWidgets('still open at 23:59:59 Cairo on the due date', (tester) async {
      final lastSecond = DateTime.utc(2026, 10, 10, 20, 59, 59);
      final backend = _backend(now: lastSecond)
        ..homework.homework.add(buildHomework(dueDate: due))
        ..homework.submissions['hw-1'] = _saved('https://a.example.com');
      backend.homework.serverNow = () => lastSecond;
      await _openDetails(tester, backend);
      expect(find.byKey(const Key('homework-link-edit')), findsOneWidget);
      expect(find.byKey(const Key('homework-link-closed')), findsNothing);
    });

    testWidgets('read-only from 00:00 Cairo the next day', (tester) async {
      final backend = _backend(now: DateTime.utc(2026, 10, 10, 21))
        ..homework.homework.add(buildHomework(dueDate: due))
        ..homework.submissions['hw-1'] = _saved('https://a.example.com');
      await _openDetails(tester, backend);

      expect(find.byKey(const Key('homework-link-closed')), findsOneWidget);
      expect(find.textContaining('انتهى موعد التسليم'), findsOneWidget);
      expect(find.text('https://a.example.com'), findsOneWidget);
      expect(find.byKey(const Key('homework-link-edit')), findsNothing);
      expect(find.byKey(const Key('homework-link-field')), findsNothing);
    });

    testWidgets('a server rejection wins over a slow device clock', (
      tester,
    ) async {
      // The device still shows the 10th, but Cairo is already the 11th.
      final backend = _backend(now: DateTime.utc(2026, 10, 10, 20))
        ..homework.homework.add(buildHomework(dueDate: due));
      backend.homework.serverNow = () => DateTime.utc(2026, 10, 10, 21, 5);
      await _openDetails(tester, backend);

      await _saveLink(tester, 'https://late.example.com');
      expect(backend.homework.submitCalls, hasLength(1));
      expect(find.byKey(const Key('homework-link-closed')), findsOneWidget);
      expect(find.textContaining('قد يختلف توقيت جهازك'), findsOneWidget);
      expect(find.byKey(const Key('homework-link-field')), findsNothing);
      // Access was re-checked with the backend and is still approved.
      expect(find.byType(StudentHomeworkDetailsScreen), findsOneWidget);
    });
  });

  testWidgets('a replaced session loses the homework on submit', (
    tester,
  ) async {
    final backend = _backend()..homework.homework.add(buildHomework());
    await _openDetails(tester, backend);

    backend.access.entries[0] = differentDeviceEntry(
      previouslyApprovedHere: true,
    );
    backend.homework.visibleGroups.clear();
    await _saveLink(tester, 'https://drive.example.com/x');

    expect(find.text('حل تمارين صفحة 42'), findsNothing);
    expect(find.text('لم يعد بإمكانك عرض الواجبات'), findsOneWidget);
  });

  testWidgets('a replaced session cannot open homework', (tester) async {
    final backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      access: FakeGroupAccessRepository([
        differentDeviceEntry(previouslyApprovedHere: true),
      ]),
      now: _now,
    )..homework.homework.add(buildHomework());
    await _openDetails(tester, backend);
    expect(find.text('حل تمارين صفحة 42'), findsNothing);
    expect(find.text('لم يعد بإمكانك عرض الواجبات'), findsOneWidget);
  });

  testWidgets('attachments download privately after an access check', (
    tester,
  ) async {
    final backend = _backend()
      ..homework.homework.add(
        buildHomework(type: HomeworkSubmissionType.none, resourceIds: ['r1']),
      )
      ..homework.resources.add(buildResource(id: 'r1', title: 'ورقة العمل'));
    await _openDetails(tester, backend);

    await tester.tap(find.byKey(const Key('homework-file-r1')));
    await tester.pumpAndSettle();
    expect(backend.files.opened, ['r1']);
    expect(backend.access.overviewFetches, greaterThan(1));

    // Revoked on the backend without a realtime event: no download.
    backend.access.entries[0] = suspendedEntry();
    backend.homework.visibleGroups.clear();
    backend.files.opened.clear();
    await tester.tap(find.byKey(const Key('homework-file-r1')));
    await tester.pumpAndSettle();
    expect(backend.files.opened, isEmpty);
    expect(find.text('ورقة العمل'), findsNothing);
  });
}
