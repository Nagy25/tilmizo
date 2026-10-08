import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import '../../helpers/fake_announcements.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  TestBackend backendWith({
    List<Announcement> announcements = const [],
    bool archived = false,
    bool suspended = false,
  }) => TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    now: testTime,
    groups: FakeGroupsRepository([
      buildGroup(id: 'group-1', isActive: !archived, isSuspended: suspended),
    ]),
    announcements: FakeAnnouncementsRepository(announcements),
  );

  Future<void> openFeed(WidgetTester tester, TestBackend backend) async {
    useTallPhone(tester);
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, AnnouncementsRoute(groupId: 'group-1'));
    expect(find.byType(AnnouncementsScreen), findsOneWidget);
  }

  Future<void> tapDelete(WidgetTester tester, [String id = 'a1']) async {
    await tester.tap(find.byKey(Key('delete-announcement-$id')));
    await tester.pumpAndSettle();
  }

  final edited = buildAnnouncement(
    id: 'a2',
    title: 'تغيير مكان الحصة',
    body: 'الحصة القادمة في القاعة الكبرى.',
    createdAt: testTime.add(const Duration(days: 1)),
    updatedAt: testTime.add(const Duration(days: 2)),
  );

  testWidgets('group details opens announcements from its own tile', (
    tester,
  ) async {
    useTallPhone(tester);
    final backend = backendWith(announcements: [buildAnnouncement()]);
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, GroupDetailsRoute(groupId: 'group-1'));

    for (final tile in ['classes', 'resources', 'payments', 'announcements']) {
      expect(find.byKey(Key('$tile-tile')), findsOneWidget);
    }
    expect(find.textContaining('آخر إعلان:'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('announcements-tile')));
    expect(find.byType(AnnouncementsScreen), findsOneWidget);
  });

  testWidgets('lists newest first with preview, date and edited mark', (
    tester,
  ) async {
    await openFeed(
      tester,
      backendWith(
        announcements: [
          buildAnnouncement(body: List.filled(12, 'سطر طويل').join('\n')),
          edited,
        ],
      ),
    );

    final newer = tester.getTopLeft(find.text('تغيير مكان الحصة'));
    final older = tester.getTopLeft(find.text('موعد الاختبار'));
    expect(newer.dy, lessThan(older.dy));
    expect(find.textContaining('نُشر '), findsNWidgets(2));
    expect(find.byKey(const Key('announcement-edited-a2')), findsOneWidget);
    expect(find.byKey(const Key('announcement-edited-a1')), findsNothing);

    // Long bodies are previewed and expand on tap.
    final body = find.textContaining('سطر طويل');
    expect(tester.widget<Text>(body).maxLines, 3);
    await tester.tap(body);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(body).maxLines, isNull);
  });

  testWidgets('publishes through the dialog and refreshes the feed', (
    tester,
  ) async {
    final backend = backendWith();
    await openFeed(tester, backend);
    expect(find.byKey(const Key('announcements-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-announcement')));
    await tester.pumpAndSettle();
    expect(find.text('إضافة إعلان جديد'), findsOneWidget);

    await tester.tap(find.byKey(const Key('announcement-submit')));
    await tester.pumpAndSettle();
    expect(find.text('اكتب عنوان الإعلان.'), findsOneWidget);
    expect(find.text('اكتب نص الإعلان.'), findsOneWidget);
    expect(backend.announcements.calls, isEmpty);

    final fetches = backend.announcements.fetches;
    await tester.enterText(
      find.byKey(const Key('announcement-title')),
      '  مراجعة نهائية ',
    );
    await tester.enterText(
      find.byKey(const Key('announcement-body')),
      'المراجعة يوم السبت.',
    );
    await tester.tap(find.byKey(const Key('announcement-submit')));
    await tester.pumpAndSettle();

    // Only the create RPC: the backend sends the student notification.
    expect(backend.announcements.calls, ['create:group-1']);
    expect(find.byKey(const Key('announcement-form-dialog')), findsNothing);
    expect(find.text('تم نشر الإعلان.'), findsOneWidget);
    expect(find.text('مراجعة نهائية'), findsOneWidget);
    expect(backend.announcements.fetches, greaterThan(fetches));
  });

  testWidgets('published announcements offer delete but no edit', (
    tester,
  ) async {
    await openFeed(tester, backendWith(announcements: [buildAnnouncement()]));

    expect(find.byKey(const Key('delete-announcement-a1')), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.text('تعديل'), findsNothing);
    expect(find.byType(PopupMenuButton), findsNothing);

    // Tapping the card only expands it; it never opens a form.
    await tester.tap(find.text('موعد الاختبار'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('announcement-form-dialog')), findsNothing);
  });

  testWidgets('deletes only after confirmation', (tester) async {
    final backend = backendWith(announcements: [buildAnnouncement()]);
    await openFeed(tester, backend);

    await tapDelete(tester);
    expect(find.text('حذف الإعلان؟'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(backend.announcements.calls, isEmpty);

    await tapDelete(tester);
    await tester.tap(find.byKey(const Key('confirm-announcement-delete')));
    await tester.pumpAndSettle();

    expect(backend.announcements.calls, ['delete:a1']);
    expect(find.text('تم حذف الإعلان.'), findsOneWidget);
    expect(find.byKey(const Key('announcement-a1')), findsNothing);
    expect(find.byKey(const Key('announcements-empty')), findsOneWidget);
  });

  testWidgets('a rejected write keeps the dialog open with a safe message', (
    tester,
  ) async {
    final backend = backendWith(announcements: [buildAnnouncement()]);
    backend.announcements.mutationFailure = const AppFailure(
      AppFailureType.notEligible,
    );
    await openFeed(tester, backend);

    await tester.tap(find.byKey(const Key('add-announcement')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('announcement-title')),
      'عنوان',
    );
    await tester.enterText(find.byKey(const Key('announcement-body')), 'نص');
    await tester.tap(find.byKey(const Key('announcement-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('announcement-form-dialog')), findsOneWidget);
    expect(
      find.text(
        'لا يمكن نشر الإعلانات أو حذفها لأن المجموعة مؤرشفة أو موقوفة مؤقتًا.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a deleted announcement reports not found on delete', (
    tester,
  ) async {
    final backend = backendWith(announcements: [buildAnnouncement()]);
    backend.announcements.mutationFailure = const AppFailure(
      AppFailureType.notFound,
    );
    await openFeed(tester, backend);

    await tapDelete(tester);
    await tester.tap(find.byKey(const Key('confirm-announcement-delete')));
    await tester.pumpAndSettle();
    expect(
      find.text('هذا الإعلان لم يعد موجودًا. تم تحديث القائمة.'),
      findsOneWidget,
    );
  });

  for (final (name, archived, notice) in [
    ('suspended', false, 'المجموعة موقوفة مؤقتًا'),
    ('archived', true, 'هذه المجموعة مؤرشفة'),
  ]) {
    testWidgets('$name groups are read-only but readable', (tester) async {
      await openFeed(
        tester,
        backendWith(
          announcements: [buildAnnouncement()],
          archived: archived,
          suspended: !archived,
        ),
      );

      expect(find.text('موعد الاختبار'), findsOneWidget);
      expect(find.textContaining(notice), findsOneWidget);
      expect(find.byKey(const Key('add-announcement')), findsNothing);
      expect(find.byKey(const Key('delete-announcement-a1')), findsNothing);
    });
  }

  testWidgets('read-only empty feeds offer no add action', (tester) async {
    await openFeed(tester, backendWith(suspended: true));
    expect(find.byKey(const Key('announcements-empty')), findsOneWidget);
    expect(find.text('إعلان جديد'), findsNothing);
  });

  testWidgets('load errors can be retried', (tester) async {
    final backend = backendWith(announcements: [buildAnnouncement()]);
    backend.announcements.fetchFailure = const AppFailure(
      AppFailureType.network,
    );
    await openFeed(tester, backend);
    expect(find.byKey(const Key('announcements-error')), findsOneWidget);

    backend.announcements.fetchFailure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.text('موعد الاختبار'), findsOneWidget);
  });
}
