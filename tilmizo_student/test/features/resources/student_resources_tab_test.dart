import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/group_access/domain/approved_group.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/approved_group_screen.dart';

import '../../helpers/fake_resources.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

TestBackend _backend() {
  final backend = TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    access: FakeGroupAccessRepository([approvedEntry()]),
  );
  backend.access.approvedGroups['group-1'] = const ApprovedGroup(
    id: 'group-1',
    name: 'مجموعة العباقرة',
  );
  return backend;
}

Future<void> _openResourcesTab(WidgetTester tester, TestBackend backend) async {
  await pumpStudentApp(tester, backend);
  await tester.tap(find.text('دخول المجموعة').last);
  await tester.pumpAndSettle();
  expect(find.byType(ApprovedGroupScreen), findsOneWidget);
  await tester.tap(find.byKey(const Key('group-tab-resources')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initTestLocalization);

  testWidgets('approved group has info, classes and resources tabs', (
    tester,
  ) async {
    final backend = _backend();
    await pumpStudentApp(tester, backend);
    await tester.tap(find.text('دخول المجموعة').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('group-tab-info')), findsOneWidget);
    expect(find.byKey(const Key('group-tab-classes')), findsOneWidget);
    expect(find.byKey(const Key('group-tab-resources')), findsOneWidget);
    expect(find.text('مغادرة المجموعة'), findsOneWidget);
  });

  testWidgets('lists resources read-only with live counts', (tester) async {
    final backend = _backend();
    backend.resources.resources.addAll([
      buildResource(id: 'a', title: 'مذكرة', description: 'اقرأ الفصل'),
      buildResource(
        id: 'b',
        title: 'محاكاة',
        type: ResourceType.externalLink,
        externalUrl: 'https://phet.colorado.edu/sim',
      ),
    ]);
    await _openResourcesTab(tester, backend);

    expect(find.text('مذكرة'), findsOneWidget);
    expect(find.text('اقرأ الفصل'), findsOneWidget);
    expect(find.text('مستند PDF • 4.2 ميجابايت'), findsOneWidget);
    expect(find.text('رابط خارجي • phet.colorado.edu'), findsOneWidget);
    expect(find.text('الكل (2)'), findsOneWidget);
    expect(find.text('عام للمجموعة'), findsNWidgets(2));
    for (final mutation in ['إضافة مورد', 'تعديل', 'حذف']) {
      expect(find.text(mutation), findsNothing);
    }
    expect(find.byIcon(Icons.offline_pin), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('student-resource-links')));
    await tester.tap(find.byKey(const Key('student-resource-links')));
    await tester.pumpAndSettle();
    expect(find.text('مذكرة'), findsNothing);
    expect(find.text('محاكاة'), findsOneWidget);
  });

  testWidgets('shows the empty state when RLS returns nothing', (tester) async {
    await _openResourcesTab(tester, _backend());
    expect(find.byKey(const Key('student-resources-empty')), findsOneWidget);
  });

  testWidgets('load errors can be retried', (tester) async {
    final backend = _backend()
      ..resources.resources.add(buildResource())
      ..resources.failure = const AppFailure(AppFailureType.network);
    await _openResourcesTab(tester, backend);
    expect(find.byKey(const Key('student-resources-error')), findsOneWidget);

    backend.resources.failure = null;
    await tester.tap(find.text('حاول مرة أخرى').last);
    await tester.pumpAndSettle();
    expect(find.text('مذكرة القوانين'), findsOneWidget);
  });

  testWidgets('opens uploads after re-checking access', (tester) async {
    final backend = _backend()..resources.resources.add(buildResource());
    await _openResourcesTab(tester, backend);

    await tester.tap(find.text('فتح ومعاينة'));
    await tester.pumpAndSettle();
    expect(backend.files.opened, ['resource-1']);
  });

  testWidgets('download failures show a retry', (tester) async {
    final backend = _backend()..resources.resources.add(buildResource());
    backend.files.failure = ResourceFileFailureType.network;
    await _openResourcesTab(tester, backend);

    await tester.tap(find.text('فتح ومعاينة'));
    await tester.pumpAndSettle();
    expect(
      find.text('لا يوجد اتصال بالإنترنت. تأكد من الشبكة وحاول مرة أخرى.'),
      findsOneWidget,
    );

    backend.files.failure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(backend.files.opened, ['resource-1']);
  });

  testWidgets('a revoked student cannot open a previously loaded file', (
    tester,
  ) async {
    final backend = _backend()..resources.resources.add(buildResource());
    await _openResourcesTab(tester, backend);
    expect(find.text('مذكرة القوانين'), findsOneWidget);

    // Suspended on the backend, but no realtime event reached the device.
    backend.access.entries[0] = suspendedEntry();
    backend.resources.visibleGroups.clear();
    await tester.tap(find.text('فتح ومعاينة'));
    await tester.pumpAndSettle();

    expect(backend.files.opened, isEmpty);
    expect(find.byType(ApprovedGroupScreen), findsNothing);
    expect(find.text('مذكرة القوانين'), findsNothing);
    expect(backend.files.clears, greaterThan(0));
  });

  testWidgets('a realtime revocation clears the resources list', (
    tester,
  ) async {
    final backend = _backend()..resources.resources.add(buildResource());
    await _openResourcesTab(tester, backend);

    backend.access.entries[0] = suspendedEntry();
    backend.resources.visibleGroups.clear();
    backend.access.changes.add(null);
    await tester.pumpAndSettle();

    expect(find.byType(ApprovedGroupScreen), findsNothing);
    expect(find.text('مذكرة القوانين'), findsNothing);
  });
}
