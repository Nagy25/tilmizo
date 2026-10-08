import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/group_access/domain/approved_group.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/approved_group_screen.dart';

import '../../helpers/fake_announcements.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

TestBackend _backend(List<Announcement> announcements) {
  final backend = TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    access: FakeGroupAccessRepository([approvedEntry()]),
  );
  backend.access.approvedGroups['group-1'] = const ApprovedGroup(
    id: 'group-1',
    name: 'مجموعة العباقرة',
  );
  backend.announcements.announcements.addAll(announcements);
  return backend;
}

Future<void> _openTab(WidgetTester tester, TestBackend backend) async {
  await pumpStudentApp(tester, backend);
  await tester.tap(find.text('دخول المجموعة').last);
  await tester.pumpAndSettle();
  expect(find.byType(ApprovedGroupScreen), findsOneWidget);
  await tester.tap(find.byKey(const Key('group-tab-announcements')));
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byKey(Key('student-announcement-$id'));
Finder _dot(String id) => find.byKey(Key('unread-dot-$id'));

final _older = buildAnnouncement(
  id: 'old',
  title: 'جدول المراجعة',
  body: 'المراجعة النهائية تبدأ الأسبوع القادم.',
  createdAt: DateTime.utc(2026, 9, 1, 8),
);

final _newer = buildAnnouncement(
  id: 'new',
  title: 'تغيير مكان الحصة',
  body: List.filled(8, 'الحصة القادمة في القاعة الكبرى.').join('\n'),
  createdAt: DateTime.utc(2026, 10, 6, 8),
  updatedAt: DateTime.utc(2026, 10, 6, 9),
);

void main() {
  setUpAll(initTestLocalization);

  testWidgets('lists newest first with unread marks and no write controls', (
    tester,
  ) async {
    final backend = _backend([_older, _newer]);
    backend.announcements.readAt['old'] = DateTime.utc(2026, 9, 2);
    await _openTab(tester, backend);

    for (final tab in ['info', 'classes', 'resources', 'payments']) {
      expect(find.byKey(Key('group-tab-$tab')), findsOneWidget);
    }
    expect(
      tester.getTopLeft(_card('new')).dy,
      lessThan(tester.getTopLeft(_card('old')).dy),
    );
    expect(_dot('new'), findsOneWidget);
    expect(_dot('old'), findsNothing);
    expect(find.text('جديد'), findsOneWidget);
    expect(find.text('معدَّل'), findsOneWidget);
    expect(find.textContaining('نُشر '), findsNWidgets(2));
    for (final mutation in ['إعلان جديد', 'تعديل', 'حذف']) {
      expect(find.text(mutation), findsNothing);
    }
    expect(find.byType(FloatingActionButton), findsNothing);

    // Loading (and reloading) the feed never records a read.
    expect(backend.announcements.markReadCalls, isEmpty);
  });

  testWidgets('a newly approved student sees older posts as unread', (
    tester,
  ) async {
    await _openTab(tester, _backend([_older, _newer]));
    expect(_dot('old'), findsOneWidget);
    expect(_dot('new'), findsOneWidget);
    expect(find.text('جديد'), findsNWidgets(2));
  });

  testWidgets('opening a post shows it fully and marks it read on success', (
    tester,
  ) async {
    final backend = _backend([_newer]);
    final pending = backend.announcements.pendingMarkRead = Completer<void>();
    await _openTab(tester, backend);

    await tester.tap(_card('new'));
    await tester.pumpAndSettle();
    final details = find.byKey(const Key('announcement-details'));
    expect(details, findsOneWidget);
    expect(
      find.descendant(of: details, matching: find.text('تغيير مكان الحصة')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: details, matching: find.byType(SelectableText)),
      findsOneWidget,
    );
    expect(backend.announcements.markReadCalls, ['new']);
    // Not marked until the RPC succeeds.
    expect(_dot('new'), findsOneWidget);

    pending.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    expect(_dot('new'), findsNothing);
    expect(find.text('جديد'), findsNothing);

    // Re-opening a read post does not call the RPC again.
    await tester.tap(_card('new'));
    await tester.pumpAndSettle();
    expect(backend.announcements.markReadCalls, ['new']);
  });

  testWidgets('a failed read mark keeps the post unread', (tester) async {
    final backend = _backend([_newer]);
    backend.announcements.markReadFailure = const AppFailure(
      AppFailureType.network,
    );
    await _openTab(tester, backend);

    await tester.tap(_card('new'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('announcement-mark-read-failed')),
      findsOneWidget,
    );
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();
    expect(_dot('new'), findsOneWidget);
  });

  testWidgets('a replaced session cannot keep reading the group', (
    tester,
  ) async {
    final backend = _backend([_newer]);
    await _openTab(tester, backend);

    // Approved on another device, but no realtime event reached this one.
    backend.access.entries[0] = differentDeviceEntry(
      previouslyApprovedHere: true,
    );
    backend.announcements.visibleGroups.clear();
    await tester.tap(_card('new'));
    await tester.pumpAndSettle();

    expect(backend.announcements.markReadCalls, ['new']);
    expect(find.byKey(const Key('announcement-details')), findsNothing);
    expect(find.byType(ApprovedGroupScreen), findsNothing);
    expect(find.text('تغيير مكان الحصة'), findsNothing);
  });

  testWidgets('pull-to-refresh and resume reload the feed', (tester) async {
    final backend = _backend([_older]);
    await _openTab(tester, backend);
    expect(_card('new'), findsNothing);

    backend.announcements.announcements.add(_newer);
    await tester.fling(_card('old'), const Offset(0, 500), 1000);
    await tester.pumpAndSettle();
    expect(_card('new'), findsOneWidget);

    final third = buildAnnouncement(
      id: 'third',
      createdAt: DateTime.utc(2026, 10, 7),
    );
    backend.announcements.announcements.add(third);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(_card('third'), findsOneWidget);
    expect(backend.announcements.markReadCalls, isEmpty);
  });

  testWidgets('shows the empty state when RLS returns nothing', (tester) async {
    await _openTab(tester, _backend([]));
    expect(
      find.byKey(const Key('student-announcements-empty')),
      findsOneWidget,
    );
  });

  testWidgets('load errors can be retried', (tester) async {
    final backend = _backend([_older])
      ..announcements.failure = const AppFailure(AppFailureType.network);
    await _openTab(tester, backend);
    expect(
      find.byKey(const Key('student-announcements-error')),
      findsOneWidget,
    );

    backend.announcements.failure = null;
    await tester.tap(find.text('حاول مرة أخرى').last);
    await tester.pumpAndSettle();
    expect(_card('old'), findsOneWidget);
  });

  testWidgets('a realtime revocation clears the feed', (tester) async {
    final backend = _backend([_older]);
    await _openTab(tester, backend);

    backend.access.entries[0] = suspendedEntry();
    backend.announcements.visibleGroups.clear();
    backend.access.changes.add(null);
    await tester.pumpAndSettle();

    expect(find.byType(ApprovedGroupScreen), findsNothing);
    expect(find.text('جدول المراجعة'), findsNothing);
  });
}
