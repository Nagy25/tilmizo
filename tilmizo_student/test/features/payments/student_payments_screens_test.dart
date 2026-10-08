import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/app/my_app.dart';
import 'package:tilmizo_student/features/group_access/domain/approved_group.dart';
import 'package:tilmizo_student/features/group_access/domain/backend_access_state.dart';
import 'package:tilmizo_student/features/payments/presentation/screens/payment_history_screen.dart';
import 'package:tilmizo_student/router/app_router.dart';

import '../../helpers/fake_payments.dart';
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

final _records = [
  buildObligation(id: 'a', piasters: 15050),
  buildObligation(
    id: 'b',
    source: PaymentSourceType.monthly,
    title: 'Monthly payment',
    piasters: 30000,
    status: PaymentStatus.paid,
    method: PaymentMethod.instapay,
  ),
  buildObligation(id: 'other-group', groupId: 'group-2', piasters: 99900),
];

Future<void> _openPaymentsTab(
  WidgetTester tester,
  TestBackend backend, {
  Size viewSize = const Size(480, 1600),
}) async {
  await pumpStudentApp(tester, backend, viewSize: viewSize);
  await _push(tester, ApprovedGroupRoute(groupId: 'group-1'));
  // On narrow phones the scrollable tab bar brings the fourth tab in view.
  await tester.ensureVisible(find.byKey(const Key('group-tab-payments')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('group-tab-payments')));
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, PageRouteInfo route) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MyApp)),
  );
  unawaited(container.read(appRouterProvider).push(route));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initTestLocalization);

  testWidgets('payments tab lists only this group, unpaid then paid', (
    tester,
  ) async {
    final backend = _backend()..payments.obligations.addAll(_records);
    await _openPaymentsTab(tester, backend);

    expect(find.text('150.50 ج.م'), findsNWidgets(2)); // Total and card.
    expect(find.text('300 ج.م'), findsOneWidget); // Paid total only.
    expect(find.text('مذكرة الفصل الأول'), findsOneWidget);
    expect(find.text('999 ج.م'), findsNothing);
    for (final forbidden in ['ادفع الآن', 'دفع', 'متأخر']) {
      expect(find.text(forbidden), findsNothing);
    }

    await tester.tap(find.byKey(const Key('student-payments-paid')));
    await tester.pumpAndSettle();
    expect(find.textContaining('اشتراك شهر أكتوبر'), findsOneWidget);
    expect(find.textContaining('إنستاباي'), findsOneWidget);
    expect(find.text('Monthly payment'), findsNothing);
  });

  testWidgets('refreshes when the tab is entered', (tester) async {
    final backend = _backend();
    await _openPaymentsTab(tester, backend);
    final before = backend.payments.fetches.length;

    // Five tabs overflow the scrollable bar, so bring each into view.
    for (final tab in ['info', 'payments']) {
      await tester.ensureVisible(find.byKey(Key('group-tab-$tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('group-tab-$tab')));
      await tester.pumpAndSettle();
    }
    expect(backend.payments.fetches.length, greaterThan(before));
  });

  testWidgets('shows the empty state', (tester) async {
    await _openPaymentsTab(tester, _backend());
    expect(find.byKey(const Key('student-payments-empty')), findsOneWidget);
  });

  testWidgets('load errors can be retried', (tester) async {
    final backend = _backend()
      ..payments.obligations.add(buildObligation())
      ..payments.failure = const AppFailure(AppFailureType.network);
    await _openPaymentsTab(tester, backend);
    expect(find.byKey(const Key('student-payments-error')), findsOneWidget);

    backend.payments.failure = null;
    await tester.tap(find.text('حاول مرة أخرى').last);
    await tester.pumpAndSettle();
    expect(find.text('مذكرة الفصل الأول'), findsOneWidget);
  });

  testWidgets('every tab stays usable on a narrow RTL phone', (tester) async {
    final backend = _backend()..payments.obligations.add(buildObligation());
    await _openPaymentsTab(tester, backend, viewSize: const Size(320, 900));
    expect(tester.takeException(), isNull);
    expect(find.text('مذكرة الفصل الأول'), findsOneWidget);
  });

  testWidgets('the account sheet opens payment history', (tester) async {
    final backend = _backend()..payments.obligations.addAll(_records);
    await pumpStudentApp(tester, backend);

    await tester.tap(find.byTooltip('الحساب'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-payment-history')));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentHistoryScreen), findsOneWidget);
    expect(find.text('مجموعة العباقرة'), findsWidgets);
    expect(find.text('999 ج.م'), findsWidgets);
  });

  testWidgets('history stays readable after leaving the group', (tester) async {
    final backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      access: FakeGroupAccessRepository([
        buildEntry(
          state: BackendAccessState.removed,
          membership: MembershipStatus.removed,
          request: JoinRequestStatus.approved,
        ),
      ]),
    )..payments.obligations.addAll(_records);
    await pumpStudentApp(tester, backend);

    await _push(tester, const PaymentHistoryRoute());

    expect(find.byType(PaymentHistoryScreen), findsOneWidget);
    expect(find.text('150.50 ج.م'), findsWidgets);
    expect(find.text('مجموعة سابقة'), findsOneWidget); // group-2 is unknown.
  });
}
