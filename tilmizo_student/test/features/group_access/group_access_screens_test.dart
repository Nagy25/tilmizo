import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/group_access/domain/backend_access_state.dart';
import 'package:tilmizo_student/features/group_access/domain/approved_group.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/access_removed_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/access_replaced_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/approved_group_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/groups_home_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/join_group_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/new_device_required_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/pending_request_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/replacement_pending_screen.dart';
import 'package:tilmizo_student/features/group_access/presentation/screens/request_rejected_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

TestBackend signedIn([List entries = const []]) => TestBackend(
  auth: FakePhoneAuthService(signedIn: true),
  access: FakeGroupAccessRepository([...entries.cast()]),
);

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

const replacedEntryArgs = (
  membership: MembershipStatus.active,
  request: JoinRequestStatus.approved,
);

void main() {
  setUpAll(initTestLocalization);

  testWidgets('join validates the code, shows the device name, and submits', (
    tester,
  ) async {
    final backend = signedIn();
    backend.access.onRequestAccess = (_) => buildEntry();
    await pumpStudentApp(tester, backend);
    await tapText(tester, 'الانضمام لمجموعة');
    expect(find.byType(JoinGroupScreen), findsOneWidget);
    expect(find.textContaining('Samsung Galaxy A54'), findsOneWidget);

    final submit = find.ancestor(
      of: find.text('إرسال طلب الانضمام'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('invite-code')), 'MATH 2025');
    await tester.pump();
    await tapText(tester, 'إرسال طلب الانضمام');
    expect(find.text('الكود غير صالح. تأكد منه بدون مسافات.'), findsOneWidget);
    expect(backend.access.inviteCodes, isEmpty);

    await tester.enterText(find.byKey(const Key('invite-code')), 'MATH-2025');
    await tester.pump();
    await tapText(tester, 'إرسال طلب الانضمام');
    expect(backend.access.inviteCodes, ['MATH-2025']);
    expect(find.byType(PendingRequestScreen), findsOneWidget);
    expect(find.text('مجموعة العباقرة'), findsOneWidget);
  });

  testWidgets('wrong code shows not-found and disables while pending', (
    tester,
  ) async {
    final backend = signedIn();
    backend.access.pendingRequest = Completer();
    await pumpStudentApp(tester, backend);
    await tapText(tester, 'الانضمام لمجموعة');
    await tester.enterText(find.byKey(const Key('invite-code')), 'NOPE');
    await tester.pump();
    await tester.tap(find.text('إرسال طلب الانضمام'));
    await tester.pump();

    final submit = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('إرسال طلب الانضمام'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(submit.onPressed, isNull);
    backend.access.pendingRequest!.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('الكود غير صحيح أو المجموعة غير نشطة حاليًا.'),
      findsOneWidget,
    );
  });

  testWidgets('pending moves to approved on a realtime change', (tester) async {
    final backend = signedIn([buildEntry()]);
    backend.access.approvedGroups['group-1'] = const ApprovedGroup(
      id: 'group-1',
      name: 'مجموعة العباقرة',
      subject: 'الرياضيات',
    );
    await pumpStudentApp(tester, backend);
    expect(find.byType(PendingRequestScreen), findsOneWidget);
    expect(find.text('خطوة 2 من 3'), findsOneWidget);

    backend.access.entries[0] = approvedEntry();
    backend.access.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(ApprovedGroupScreen), findsOneWidget);
    expect(find.text('أنت مشترك في المجموعة'), findsWidgets);
  });

  testWidgets('rejected request offers a new request', (tester) async {
    await pumpStudentApp(
      tester,
      signedIn([
        buildEntry(
          state: BackendAccessState.rejected,
          request: JoinRequestStatus.rejected,
        ),
      ]),
    );
    expect(find.byType(RequestRejectedScreen), findsOneWidget);
    await tapText(tester, 'إرسال طلب جديد بالكود');
    expect(find.byType(JoinGroupScreen), findsOneWidget);
  });

  testWidgets('new device requests replacement without the invite code', (
    tester,
  ) async {
    final backend = signedIn([differentDeviceEntry()]);
    await pumpStudentApp(tester, backend);
    expect(find.byType(NewDeviceRequiredScreen), findsOneWidget);
    expect(find.text('iPhone 13'), findsOneWidget);
    expect(find.textContaining('يبقى جهازك السابق مفعّلًا'), findsOneWidget);
    expect(find.byKey(const Key('invite-code')), findsNothing);

    await tapText(tester, 'طلب اعتماد هذا الجهاز');
    expect(backend.access.replacementRequests, ['membership-group-1']);
    expect(find.byType(ReplacementPendingScreen), findsOneWidget);
  });

  testWidgets('old device shows the replaced state', (tester) async {
    await pumpStudentApp(
      tester,
      signedIn([differentDeviceEntry(previouslyApprovedHere: true)]),
    );
    expect(find.byType(AccessReplacedScreen), findsOneWidget);
    expect(find.text('تم نقل وصولك إلى جهاز آخر'), findsWidgets);
  });

  testWidgets('approved device moves to replaced and drops group data', (
    tester,
  ) async {
    final backend = signedIn([approvedEntry()]);
    backend.access.approvedGroups['group-1'] = const ApprovedGroup(
      id: 'group-1',
      name: 'مجموعة العباقرة',
    );
    await pumpStudentApp(tester, backend);
    await tapText(tester, 'دخول المجموعة');
    expect(find.byType(ApprovedGroupScreen), findsOneWidget);

    // Teacher approved another device: RLS now hides the group.
    backend.access.approvedGroups.clear();
    backend.access.entries[0] = differentDeviceEntry(
      previouslyApprovedHere: true,
    );
    backend.access.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(AccessReplacedScreen), findsOneWidget);
    expect(find.byType(ApprovedGroupScreen), findsNothing);
  });

  testWidgets('RLS denial on the approved screen re-resolves the flow', (
    tester,
  ) async {
    final backend = signedIn([approvedEntry()]);
    await pumpStudentApp(tester, backend);
    // Overview still says approved, but RLS returns nothing.
    backend.access.entries[0] = suspendedEntry();
    await tapText(tester, 'دخول المجموعة');
    expect(find.byType(AccessRemovedScreen), findsOneWidget);
  });

  testWidgets('suspended access shows the removed state', (tester) async {
    await pumpStudentApp(tester, signedIn([suspendedEntry()]));
    expect(find.byType(AccessRemovedScreen), findsOneWidget);
    expect(find.text('تم إيقاف وصولك للمجموعة'), findsWidgets);
  });

  testWidgets('home lists approved groups and needs no dead tabs', (
    tester,
  ) async {
    await pumpStudentApp(
      tester,
      signedIn([
        approvedEntry(),
        buildEntry(groupId: 'g2', groupName: 'فيزياء'),
      ]),
    );
    expect(find.byType(GroupsHomeScreen), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('مجموعاتي الحالية'), findsOneWidget);
    expect(find.text('طلبات قيد المراجعة'), findsOneWidget);
    expect(find.text('Samsung Galaxy A54 (هذا الجهاز)'), findsOneWidget);
  });

  testWidgets('refresh status reports when nothing changed', (tester) async {
    await pumpStudentApp(tester, signedIn([buildEntry()]));
    await tapText(tester, 'تحديث حالة الطلب');
    expect(find.text('لا تزال الحالة كما هي.'), findsOneWidget);
  });
}
