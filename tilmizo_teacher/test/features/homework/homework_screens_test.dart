import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/homework/domain/homework_repository.dart';
import 'package:tilmizo_teacher/features/homework/presentation/screens/add_homework_screen.dart';
import 'package:tilmizo_teacher/features/homework/presentation/screens/group_homework_screen.dart';
import 'package:tilmizo_teacher/features/homework/presentation/screens/homework_details_screen.dart';
import 'package:tilmizo_teacher/features/resources/presentation/screens/add_resource_screen.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import '../../helpers/fake_classes.dart';
import '../../helpers/fake_homework.dart';
import '../../helpers/fake_resources.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  TestBackend backendWith({
    List<Homework> homework = const [],
    List<GroupResource> resources = const [],
    bool archived = false,
    bool suspended = false,
    SessionStatus sessionStatus = SessionStatus.scheduled,
  }) => TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    now: testTime,
    groups: FakeGroupsRepository([
      buildGroup(id: 'group-1', isActive: !archived, isSuspended: suspended),
    ]),
    classes: FakeClassesRepository(
      sessions: [
        buildSession(
          groupActive: !archived,
          groupSuspended: suspended,
          status: sessionStatus,
        ),
      ],
    ),
    homework: FakeHomeworkRepository(homework: homework, resources: resources),
  );

  Future<void> open(
    WidgetTester tester,
    TestBackend backend,
    PageRouteInfo<Object?> route,
  ) async {
    useTallPhone(tester);
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, route);
  }

  Future<void> publish(WidgetTester tester) async {
    await tapVisible(tester, find.byKey(const Key('publish-homework')));
  }

  final general = buildResource(id: 'general', title: 'مذكرة عامة');
  final forSession = buildResource(
    id: 'session-file',
    title: 'ورقة الحصة',
    sessionId: 'session-1',
  );
  final otherSession = buildResource(
    id: 'other-file',
    title: 'ملف حصة أخرى',
    sessionId: 'session-2',
  );
  final link = buildResource(
    id: 'link',
    title: 'رابط محاكاة',
    type: ResourceType.externalLink,
  );

  testWidgets('group details opens the homework list from its tile', (
    tester,
  ) async {
    final backend = backendWith(homework: [buildHomework()]);
    await open(tester, backend, GroupDetailsRoute(groupId: 'group-1'));

    expect(find.text('واجب واحد'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('homework-tile')));
    expect(find.byType(GroupHomeworkScreen), findsOneWidget);
    expect(find.textContaining('واجب حصة'), findsOneWidget);
    expect(find.text('حل تمارين صفحة 42'), findsOneWidget);
    expect(find.text('تسليم رابط'), findsOneWidget);

    await tester.tap(find.byKey(const Key('homework-hw-1')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeworkDetailsScreen), findsOneWidget);
  });

  testWidgets('empty and error states', (tester) async {
    final backend = backendWith();
    await open(tester, backend, GroupHomeworkRoute(groupId: 'group-1'));
    expect(find.byKey(const Key('homework-empty')), findsOneWidget);
    expect(find.text('عرض حصص المجموعة'), findsOneWidget);

    backend.homework
      ..homework.add(buildHomework())
      ..fetchFailure = const AppFailure(AppFailureType.network);
    await tester.fling(
      find.byKey(const Key('homework-empty')),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homework-error')), findsOneWidget);

    backend.homework.fetchFailure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homework-hw-1')), findsOneWidget);
  });

  testWidgets('session details lists homework and starts adding', (
    tester,
  ) async {
    final backend = backendWith(homework: [buildHomework()]);
    await open(tester, backend, SessionDetailsRoute(sessionId: 'session-1'));

    expect(find.byKey(const Key('session-homework-card')), findsOneWidget);
    expect(find.byKey(const Key('homework-hw-1')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('add-homework')));
    expect(find.byType(AddHomeworkScreen), findsOneWidget);
  });

  testWidgets('requires instructions or a file', (tester) async {
    final backend = backendWith();
    await open(tester, backend, AddHomeworkRoute(sessionId: 'session-1'));

    await publish(tester);
    expect(
      find.text('اكتب التعليمات أو أرفق ملفًا واحدًا على الأقل.'),
      findsOneWidget,
    );
    expect(backend.homework.calls, isEmpty);
  });

  testWidgets('publishes text-only homework and refreshes the session', (
    tester,
  ) async {
    final backend = backendWith();
    await open(tester, backend, SessionDetailsRoute(sessionId: 'session-1'));
    await tapVisible(tester, find.byKey(const Key('add-homework')));

    await tester.enterText(
      find.byKey(const Key('homework-instructions')),
      'حل تمارين الفصل الثالث',
    );
    await publish(tester);

    final draft = backend.homework.drafts.single;
    expect(draft.trimmedInstructions, 'حل تمارين الفصل الثالث');
    expect(draft.resourceIds, isEmpty);
    expect(draft.submissionType, HomeworkSubmissionType.manual);
    expect(draft.dueDate, isNull);
    expect(find.byType(AddHomeworkScreen), findsNothing);
    expect(find.text('تم نشر الواجب.'), findsOneWidget);
    expect(find.text('حل تمارين الفصل الثالث'), findsOneWidget);
  });

  testWidgets('offers only compatible uploads and publishes files only', (
    tester,
  ) async {
    final backend = backendWith(
      resources: [general, forSession, otherSession, link],
    );
    await open(tester, backend, AddHomeworkRoute(sessionId: 'session-1'));

    expect(find.byKey(const Key('attach-general')), findsOneWidget);
    expect(find.byKey(const Key('attach-session-file')), findsOneWidget);
    expect(find.byKey(const Key('attach-other-file')), findsNothing);
    expect(find.byKey(const Key('attach-link')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('attach-session-file')));
    await tapVisible(tester, find.byKey(const Key('homework-type-none')));
    await publish(tester);

    final draft = backend.homework.drafts.single;
    expect(draft.trimmedInstructions, isNull);
    expect(draft.resourceIds, ['session-file']);
    expect(draft.submissionType, HomeworkSubmissionType.none);
  });

  testWidgets('publishes both with a link type and a Cairo due date', (
    tester,
  ) async {
    final backend = backendWith(resources: [general]);
    await open(tester, backend, AddHomeworkRoute(sessionId: 'session-1'));

    await tester.enterText(
      find.byKey(const Key('homework-instructions')),
      'أرسل رابط العرض',
    );
    await tapVisible(tester, find.byKey(const Key('attach-general')));
    await tapVisible(tester, find.byKey(const Key('homework-type-link')));
    await tapVisible(tester, find.text('اختيار تاريخ'));
    final ok = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    ).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
    expect(
      find.text('تُقبل روابط الطلاب حتى نهاية هذا اليوم بتوقيت القاهرة.'),
      findsOneWidget,
    );
    await publish(tester);

    final draft = backend.homework.drafts.single;
    expect(draft.resourceIds, ['general']);
    expect(draft.submissionType, HomeworkSubmissionType.link);
    // Today in Cairo for the fixed test clock (2026-10-01 12:00 Cairo).
    expect(draft.dueDate, DateTime.utc(2026, 10, 1));
  });

  testWidgets('uploads through the Resource flow, then attaches the file', (
    tester,
  ) async {
    final backend = backendWith(resources: [general]);
    await open(tester, backend, AddHomeworkRoute(sessionId: 'session-1'));

    await tapVisible(tester, find.byKey(const Key('homework-upload-file')));
    // Links are Resources but never homework attachments.
    expect(find.byKey(const Key('resource-type-pdf')), findsOneWidget);
    expect(find.byKey(const Key('resource-type-external_link')), findsNothing);
    await tester.tap(find.byKey(const Key('resource-type-pdf')));
    await tester.pumpAndSettle();
    final addResource = tester.widget<AddResourceScreen>(
      find.byType(AddResourceScreen),
    );
    expect(addResource.sessionId, 'session-1');

    // The upload finished in the Resource flow.
    backend.homework.resources.add(
      buildResource(id: 'uploaded', title: 'ملف جديد', sessionId: 'session-1'),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AddResourceScreen)),
    );
    await container.read(appRouterProvider).maybePop();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('attach-uploaded')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('attach-uploaded')));
    await publish(tester);
    expect(backend.homework.drafts.single.resourceIds, ['uploaded']);
  });

  testWidgets('a rejected create keeps the form with a safe message', (
    tester,
  ) async {
    final backend = backendWith();
    backend.homework.mutationFailure = const HomeworkFailure(
      HomeworkFailureReason.groupNotWritable,
    );
    await open(tester, backend, AddHomeworkRoute(sessionId: 'session-1'));
    await tester.enterText(
      find.byKey(const Key('homework-instructions')),
      'نص',
    );
    await publish(tester);
    expect(find.byType(AddHomeworkScreen), findsOneWidget);
    expect(
      find.text(
        'لا يمكن إضافة الواجبات أو حذفها لأن المجموعة مؤرشفة أو موقوفة مؤقتًا.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('details show files, students links, and delete keeps files', (
    tester,
  ) async {
    final backend = backendWith(
      homework: [
        buildHomework(
          resourceIds: ['general'],
          dueDate: DateTime.utc(2026, 10, 10),
        ),
      ],
      resources: [general],
    );
    backend.homework.submissions['hw-1'] = [
      TeacherHomeworkSubmission(
        studentName: 'سارة أحمد',
        submission: HomeworkLinkSubmission(
          homeworkId: 'hw-1',
          studentId: 'st1',
          url: 'https://drive.example.com/sara',
          createdAt: testTime,
          updatedAt: testTime,
        ),
      ),
    ];
    await open(tester, backend, HomeworkDetailsRoute(homeworkId: 'hw-1'));

    expect(find.text('حل تمارين صفحة 42'), findsOneWidget);
    expect(find.textContaining('آخر موعد:'), findsOneWidget);
    expect(find.text('سارة أحمد'), findsOneWidget);
    expect(find.text('https://drive.example.com/sara'), findsOneWidget);
    expect(find.text('تعديل'), findsNothing);

    // Attachments open through the private downloader.
    await tapVisible(
      tester,
      find.byKey(const Key('homework-attachment-general')),
    );
    expect(backend.files.opened, ['general']);

    await tapVisible(tester, find.byKey(const Key('delete-homework')));
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(backend.homework.calls, isEmpty);

    await tapVisible(tester, find.byKey(const Key('delete-homework')));
    await tester.tap(find.byKey(const Key('confirm-homework-delete')));
    await tester.pumpAndSettle();
    expect(backend.homework.calls, ['delete:hw-1']);
    expect(backend.homework.resources, [general]);
    expect(backend.resources.calls, isEmpty);
    expect(find.byType(HomeworkDetailsScreen), findsNothing);
    expect(find.text('تم حذف الواجب.'), findsOneWidget);
  });

  for (final (name, archived, suspended, status) in [
    ('suspended group', false, true, SessionStatus.scheduled),
    ('archived group', true, false, SessionStatus.scheduled),
    ('cancelled session', false, false, SessionStatus.cancelled),
  ]) {
    testWidgets('$name hides create and delete but stays readable', (
      tester,
    ) async {
      final backend = backendWith(
        homework: [buildHomework(sessionStatus: status)],
        archived: archived,
        suspended: suspended,
        sessionStatus: status,
      );
      await open(tester, backend, SessionDetailsRoute(sessionId: 'session-1'));
      expect(find.byKey(const Key('homework-hw-1')), findsOneWidget);
      expect(find.byKey(const Key('add-homework')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('homework-hw-1')));
      expect(find.byType(HomeworkDetailsScreen), findsOneWidget);
      expect(find.text('حل تمارين صفحة 42'), findsOneWidget);
      expect(find.byKey(const Key('delete-homework')), findsNothing);
    });
  }

  testWidgets('read-only groups explain why in the list', (tester) async {
    await open(
      tester,
      backendWith(homework: [buildHomework()], suspended: true),
      GroupHomeworkRoute(groupId: 'group-1'),
    );
    expect(find.byKey(const Key('homework-read-only')), findsOneWidget);
    expect(find.byKey(const Key('homework-hw-1')), findsOneWidget);
  });
}
