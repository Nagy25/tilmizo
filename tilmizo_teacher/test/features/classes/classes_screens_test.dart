import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/classes/domain/class_session.dart';
import 'package:tilmizo_teacher/features/classes/domain/schedule_entry.dart';
import 'package:tilmizo_teacher/features/classes/domain/session_location.dart';
import 'package:tilmizo_teacher/features/classes/presentation/screens/classes_screen.dart';
import 'package:tilmizo_teacher/features/classes/presentation/screens/session_details_screen.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import '../../helpers/fake_classes.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

Future<void> tapChip(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initTestLocalization);

  TestBackend backendWith({
    List<ClassSession>? sessions,
    List<ScheduleEntry>? entries,
    bool archived = false,
  }) => TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    now: testTime,
    groups: FakeGroupsRepository([
      buildGroup(id: 'group-1', isActive: !archived),
    ]),
    classes: FakeClassesRepository(sessions: sessions, entries: entries),
  );

  testWidgets('home tile opens a true empty state with scheduling choices', (
    tester,
  ) async {
    useTallPhone(tester);
    await pumpTeacherApp(tester, backendWith());
    expect(find.text('لا توجد حصص قادمة'), findsOneWidget);

    await tester.tap(find.byKey(const Key('classes-tile')));
    await tester.pumpAndSettle();
    expect(find.byType(ClassesScreen), findsOneWidget);
    expect(find.text('لا توجد حصص مجدولة بعد'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-classes')));
    await tester.pumpAndSettle();
    expect(find.text('جدول أسبوعي متكرر'), findsOneWidget);
    expect(find.text('حصة لمرة واحدة'), findsOneWidget);
  });

  testWidgets('lists sessions by view and opens details', (tester) async {
    useTallPhone(tester);
    await pumpTeacherApp(
      tester,
      backendWith(
        sessions: [
          buildSession(notes: 'إحضار الآلة الحاسبة'),
          buildSession(
            id: 'old',
            startsAt: DateTime.utc(2026, 9, 20, 14),
            status: SessionStatus.completed,
          ),
          buildSession(
            id: 'off',
            startsAt: DateTime.utc(2026, 10, 5, 14),
            status: SessionStatus.cancelled,
          ),
        ],
      ),
    );
    expect(find.textContaining('الحصة القادمة'), findsOneWidget);
    await openRoute(tester, ClassesRoute(groupId: 'group-1'));

    expect(find.byKey(const Key('session-card-session-1')), findsOneWidget);
    expect(find.byKey(const Key('session-card-old')), findsNothing);
    expect(find.text('سنتر الأوائل'), findsOneWidget);

    await tapChip(tester, const Key('sessions-view-past'));
    expect(find.byKey(const Key('session-card-old')), findsOneWidget);

    await tapChip(tester, const Key('sessions-view-cancelled'));
    await tapVisible(tester, find.byKey(const Key('session-card-off')));
    expect(find.byType(SessionDetailsScreen), findsOneWidget);
    expect(find.text('ملغاة'), findsWidgets);
    expect(find.byKey(const Key('session-restore')), findsOneWidget);
    expect(find.byKey(const Key('session-cancel')), findsNothing);
  });

  testWidgets('a failed load can be retried', (tester) async {
    useTallPhone(tester);
    final backend = backendWith(sessions: [buildSession()]);
    await pumpTeacherApp(tester, backend);
    backend.classes.fetchFailure = const AppFailure(AppFailureType.network);
    await openRoute(tester, ClassesRoute(groupId: 'group-1'));
    expect(find.text('تعذّر تحميل الحصص'), findsOneWidget);

    backend.classes.fetchFailure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('session-card-session-1')), findsOneWidget);
  });

  testWidgets('archived groups are read-only history', (tester) async {
    useTallPhone(tester);
    await pumpTeacherApp(
      tester,
      backendWith(archived: true, sessions: [buildSession(groupActive: false)]),
    );
    await openRoute(tester, ClassesRoute(groupId: 'group-1'));
    expect(find.byKey(const Key('add-classes')), findsNothing);
    expect(find.byKey(const Key('open-weekly-schedule')), findsNothing);

    await openRoute(tester, SessionDetailsRoute(sessionId: 'session-1'));
    expect(find.text('عرض الحضور'), findsOneWidget);
    expect(find.byKey(const Key('session-edit')), findsNothing);
    expect(find.byKey(const Key('session-cancel')), findsNothing);
    expect(find.byKey(const Key('edit-session-notes')), findsNothing);

    await openRoute(tester, OneTimeSessionRoute(groupId: 'group-1'));
    expect(find.byKey(const Key('create-one-time-session')), findsNothing);
  });

  testWidgets('cancelling asks for confirmation and keeps the session', (
    tester,
  ) async {
    useTallPhone(tester);
    final backend = backendWith(
      sessions: [buildSession(startsAt: DateTime.utc(2026, 10, 3, 14))],
    );
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, SessionDetailsRoute(sessionId: 'session-1'));
    expect(find.text('يُفتح تسجيل الحضور في يوم الحصة.'), findsOneWidget);
    expect(find.text('بعد يومين'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('session-cancel')));
    expect(find.text('إلغاء الحصة؟'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-cancel-session')));
    await tester.pumpAndSettle();

    expect(backend.classes.updates.single.change, 'cancelled');
    expect(find.byKey(const Key('session-restore')), findsOneWidget);
    expect(backend.classes.sessions.single.isCancelled, isTrue);
  });

  testWidgets('an in-progress session can be completed and noted', (
    tester,
  ) async {
    useTallPhone(tester);
    final backend = backendWith(
      sessions: [buildSession(startsAt: DateTime.utc(2026, 10, 1, 8, 30))],
    );
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, SessionDetailsRoute(sessionId: 'session-1'));
    expect(find.text('جارية الآن'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-session-notes')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('session-notes-field')),
      'اختبار قصير',
    );
    await tester.tap(find.byKey(const Key('save-session-notes')));
    await tester.pumpAndSettle();
    expect(backend.classes.sessions.single.notes, 'اختبار قصير');
    expect(find.text('اختبار قصير'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('session-complete')));
    expect(backend.classes.sessions.single.status, SessionStatus.completed);
  });

  testWidgets('session edit switches a session online with a valid link', (
    tester,
  ) async {
    useTallPhone(tester);
    final backend = backendWith(sessions: [buildSession()]);
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, SessionEditRoute(sessionId: 'session-1'));

    await tester.tap(find.byKey(const Key('edit-mode-location')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('أونلاين'));
    await tester.enterText(
      find.byKey(const Key('location-link-field')),
      'http://meet.example.com/a',
    );
    await tapVisible(tester, find.byKey(const Key('submit-session-edit')));
    expect(find.text('أدخل رابطًا صحيحًا يبدأ بـ https://'), findsOneWidget);
    expect(backend.classes.updates, isEmpty);

    await tester.enterText(
      find.byKey(const Key('location-link-field')),
      'https://meet.example.com/a',
    );
    await tapVisible(tester, find.byKey(const Key('submit-session-edit')));
    expect(
      backend.classes.sessions.single.location,
      const SessionLocation.online('https://meet.example.com/a'),
    );
  });

  testWidgets('weekly form requires days and a complete slot', (tester) async {
    useTallPhone(tester);
    final backend = backendWith();
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, WeeklyScheduleFormRoute(groupId: 'group-1'));

    await tapVisible(tester, find.byKey(const Key('save-weekly-schedule')));
    expect(find.text('اختر يومًا واحدًا على الأقل.'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('weekday-7')));
    expect(find.text('يوم الأحد'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('save-weekly-schedule')));
    expect(find.text('اختر الوقت.'), findsNWidgets(2));
    expect(find.text('أدخل مكان الحصة.'), findsOneWidget);
    expect(backend.classes.createdSlots, isEmpty);
  });

  testWidgets('editing a weekly slot saves only that slot', (tester) async {
    useTallPhone(tester);
    const slot = WeeklySlot(
      weekday: 7,
      start: ClockTime(17, 0),
      end: ClockTime(18, 30),
      location: SessionLocation.physical('سنتر الأوائل'),
    );
    final backend = backendWith(
      entries: [
        const ScheduleEntry(
          id: 'e1',
          groupId: 'group-1',
          slot: slot,
          isActive: true,
        ),
      ],
    );
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, GroupScheduleRoute(groupId: 'group-1'));
    expect(find.text('الأحد'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-entry-e1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('location-place-field')),
      'قاعة 5',
    );
    await tapVisible(tester, find.byKey(const Key('save-schedule-entry')));
    expect(
      backend.classes.entries.single.slot.location,
      const SessionLocation.physical('قاعة 5'),
    );
    expect(find.text('قاعة 5'), findsOneWidget);

    await tester.tap(find.byKey(const Key('deactivate-entry-e1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إيقاف الموعد'));
    await tester.pumpAndSettle();
    expect(backend.classes.entries.single.isActive, isFalse);
    expect(find.text('لا يوجد جدول أسبوعي'), findsOneWidget);
  });

  testWidgets('one-time form validates date, times, and link', (tester) async {
    useTallPhone(tester);
    final backend = backendWith();
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, OneTimeSessionRoute(groupId: 'group-1'));

    await tapVisible(tester, find.text('أونلاين'));
    await tapVisible(tester, find.byKey(const Key('create-one-time-session')));
    expect(find.text('اختر تاريخ الحصة.'), findsOneWidget);
    expect(find.text('أدخل رابط الحصة.'), findsOneWidget);
    expect(backend.classes.createdDrafts, isEmpty);
  });
}
