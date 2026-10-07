import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/classes/presentation/screens/one_time_session_screen.dart';
import 'package:tilmizo_teacher/features/payments/domain/payment_models.dart';
import 'package:tilmizo_teacher/features/payments/presentation/screens/group_payments_screen.dart';
import 'package:tilmizo_teacher/features/payments/presentation/screens/monthly_plan_screen.dart';
import 'package:tilmizo_teacher/features/payments/presentation/screens/one_time_payment_screen.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import '../../helpers/fake_payments.dart';
import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestLocalization);

  TestBackend backendWith({
    List<StudentPaymentRecord> records = const [],
    MonthlyPaymentPlan? plan,
    bool archived = false,
    bool suspended = false,
  }) => TestBackend(
    auth: FakePhoneAuthService(signedIn: true),
    now: testTime,
    groups: FakeGroupsRepository([
      buildGroup(id: 'group-1', isActive: !archived, isSuspended: suspended),
    ]),
    payments: FakePaymentsRepository(records: records, plan: plan),
  );

  final plan = MonthlyPaymentPlan(
    id: 'plan-1',
    groupId: 'group-1',
    amount: egp(300),
    startedMonth: DateTime.utc(2026, 9),
    dueDay: 10,
  );

  Future<void> openPayments(WidgetTester tester, TestBackend backend) async {
    useTallPhone(tester);
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, GroupPaymentsRoute(groupId: 'group-1'));
    expect(find.byType(GroupPaymentsScreen), findsOneWidget);
  }

  testWidgets('group details opens payments from a distinct tile', (
    tester,
  ) async {
    useTallPhone(tester);
    final backend = backendWith(records: [buildRecord(amount: 150)]);
    await pumpTeacherApp(tester, backend);
    await openRoute(tester, GroupDetailsRoute(groupId: 'group-1'));

    expect(find.byKey(const Key('resources-tile')), findsOneWidget);
    expect(find.text('غير مسدّد: 150 ج.م'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('payments-tile')));
    expect(find.byType(GroupPaymentsScreen), findsOneWidget);
  });

  testWidgets('empty state offers the add-payment type picker', (tester) async {
    await openPayments(tester, backendWith());
    expect(find.byKey(const Key('payments-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-payment')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('payment-type-monthly')), findsOneWidget);
    expect(find.byKey(const Key('payment-type-oneTime')), findsOneWidget);

    // The session option leads to session creation, not a group payment.
    await tester.tap(find.byKey(const Key('payment-type-session')));
    await tester.pumpAndSettle();
    expect(find.byType(OneTimeSessionScreen), findsOneWidget);
    expect(find.byKey(const Key('session-payment-amount')), findsOneWidget);
  });

  testWidgets('load errors can be retried', (tester) async {
    final backend = backendWith(records: [buildRecord()]);
    backend.payments.fetchFailure = const AppFailure(AppFailureType.network);
    await openPayments(tester, backend);
    expect(find.byKey(const Key('payments-error')), findsOneWidget);

    backend.payments.fetchFailure = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('payments-summary')), findsOneWidget);
  });

  testWidgets('shows totals and splits unpaid and paid records', (
    tester,
  ) async {
    await openPayments(
      tester,
      backendWith(
        plan: plan,
        records: [
          buildRecord(id: 'a', amount: 150),
          buildRecord(
            id: 'b',
            studentName: 'عمر خالد',
            source: PaymentSourceType.monthly,
            title: 'Monthly payment',
            amount: 300,
            status: PaymentStatus.paid,
            method: PaymentMethod.instapay,
          ),
        ],
      ),
    );

    expect(find.text('450 ج.م'), findsOneWidget);
    expect(find.text('300 ج.م شهريًا'), findsOneWidget);
    expect(find.text('غير مسدّد (1)'), findsOneWidget);
    expect(find.text('مسدّد (1)'), findsOneWidget);
    expect(find.text('سارة أحمد'), findsOneWidget);
    expect(find.text('مذكرة الفصل الأول'), findsOneWidget);
    expect(find.text('عمر خالد'), findsNothing);

    await tester.tap(find.byKey(const Key('payments-filter-paid')));
    await tester.pumpAndSettle();
    expect(find.text('عمر خالد'), findsOneWidget);
    expect(find.textContaining('اشتراك شهر أكتوبر'), findsOneWidget);
    expect(find.textContaining('إنستاباي'), findsOneWidget);
    expect(find.text('Monthly payment'), findsNothing);
  });

  testWidgets('keeps Add visible but blocks a second monthly plan', (
    tester,
  ) async {
    await openPayments(
      tester,
      backendWith(plan: plan, records: [buildRecord()]),
    );
    await tapVisible(tester, find.byKey(const Key('add-another-payment')));
    expect(find.byKey(const Key('payment-type-monthly')), findsOneWidget);
    final monthly = tester.widget<ListTile>(
      find.byKey(const Key('payment-type-monthly')),
    );
    expect(monthly.enabled, isFalse);
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('payment-type-oneTime')))
          .enabled,
      isTrue,
    );
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('payment-type-session')))
          .enabled,
      isTrue,
    );
  });

  testWidgets('marks an unpaid record paid in full with one method', (
    tester,
  ) async {
    final backend = backendWith(records: [buildRecord(amount: 150)]);
    await openPayments(tester, backend);

    await tester.tap(find.byKey(const Key('mark-paid-o1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mark-paid-amount')), findsOneWidget);
    expect(find.byType(TextField), findsNothing); // No partial amount input.
    await tester.tap(find.byKey(const Key('payment-method-wallet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-mark-paid')));
    await tester.pumpAndSettle();

    expect(backend.payments.calls, ['markPaid:o1:wallet']);
    expect(find.text('تم تسجيل السداد.'), findsOneWidget);
    expect(find.text('غير مسدّد (0)'), findsOneWidget);
    expect(find.text('مسدّد (1)'), findsOneWidget);
  });

  testWidgets('voids a paid mark only after confirmation', (tester) async {
    final backend = backendWith(
      records: [buildRecord(status: PaymentStatus.paid)],
    );
    await openPayments(tester, backend);
    await tester.tap(find.byKey(const Key('payments-filter-paid')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('void-paid-o1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(backend.payments.calls, isEmpty);

    await tester.tap(find.byKey(const Key('void-paid-o1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-void-paid')));
    await tester.pumpAndSettle();
    expect(backend.payments.calls, ['void:receipt-o1']);
    expect(find.text('مسدّد (0)'), findsOneWidget);
    expect(find.text('غير مسدّد (1)'), findsOneWidget);
  });

  testWidgets('configures a new monthly plan with amount validation', (
    tester,
  ) async {
    final backend = backendWith(records: [buildRecord()]);
    await openPayments(tester, backend);
    await tester.tap(find.byKey(const Key('monthly-plan-set-up')));
    await tester.pumpAndSettle();
    expect(find.byType(MonthlyPlanScreen), findsOneWidget);
    expect(find.byKey(const Key('monthly-plan-edit-notice')), findsNothing);

    final field = find.byKey(const Key('payment-amount-field'));
    for (final (text, error) in [
      ('', 'أدخل المبلغ.'),
      ('0', 'يجب أن يكون المبلغ أكبر من صفر.'),
      ('12.345', 'استخدم رقمين عشريين على الأكثر.'),
    ]) {
      await tester.enterText(field, text);
      await tester.tap(find.byKey(const Key('save-monthly-plan')));
      await tester.pumpAndSettle();
      expect(find.text(error), findsOneWidget);
    }
    expect(backend.payments.calls, isEmpty);

    await tester.enterText(field, '٢٥٠٫٥');
    await tester.tap(find.byKey(const Key('save-monthly-plan')));
    await tester.pumpAndSettle();
    expect(backend.payments.calls, ['configure:group-1:250.50:1:fixedDay']);
    expect(find.byType(GroupPaymentsScreen), findsOneWidget);
    expect(find.text('250.50 ج.م شهريًا'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('add-another-payment')));
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('payment-type-monthly')))
          .enabled,
      isFalse,
    );
  });

  testWidgets('editing explains that existing records do not change', (
    tester,
  ) async {
    final backend = backendWith(plan: plan, records: [buildRecord()]);
    await openPayments(tester, backend);
    expect(
      find.text(
        'تعديل المبلغ أو طريقة الاستحقاق أو إيقاف الاشتراك لا يغيّر السجلات الحالية.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('monthly-plan-edit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('monthly-plan-edit-notice')), findsOneWidget);
    expect(find.text('300'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('payment-amount-field')),
      '350',
    );
    await tester.tap(find.byKey(const Key('save-monthly-plan')));
    await tester.pumpAndSettle();
    expect(backend.payments.calls, ['configure:group-1:350:10:fixedDay']);
    // Existing records keep their snapshot amount.
    expect(find.text('150 ج.م'), findsWidgets);
  });

  testWidgets('a new plan picks its due day from the 1–31 grid', (
    tester,
  ) async {
    final backend = backendWith(records: [buildRecord()]);
    await openPayments(tester, backend);
    await tester.tap(find.byKey(const Key('monthly-plan-set-up')));
    await tester.pumpAndSettle();
    expect(find.text('اليوم الأول من كل شهر'), findsOneWidget);
    expect(find.byKey(const Key('due-day-clamp-note')), findsNothing);

    await tester.tap(find.byKey(const Key('monthly-due-specificDay')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('due-day-field')));
    expect(find.byKey(const Key('due-day-31')), findsOneWidget);
    expect(find.byKey(const Key('due-day-32')), findsNothing);
    await tester.tap(find.byKey(const Key('due-day-31')));
    await tester.pumpAndSettle();
    expect(find.text('يوم 31 من كل شهر'), findsOneWidget);
    expect(find.byKey(const Key('due-day-clamp-note')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('payment-amount-field')),
      '200',
    );
    await tapVisible(tester, find.byKey(const Key('save-monthly-plan')));
    expect(backend.payments.calls, ['configure:group-1:200:31:fixedDay']);
    expect(find.text('يُستحق يوم 31 من كل شهر'), findsOneWidget);
  });

  testWidgets('changing only the due day saves the plan', (tester) async {
    final backend = backendWith(plan: plan, records: [buildRecord()]);
    await openPayments(tester, backend);
    expect(find.text('يُستحق يوم 10 من كل شهر'), findsOneWidget);

    await tester.tap(find.byKey(const Key('monthly-plan-edit')));
    await tester.pumpAndSettle();
    expect(find.text('يوم 10 من كل شهر'), findsOneWidget);
    expect(find.textContaining('يوم الاستحقاق الحالي'), findsOneWidget);

    // Saving without changes sends nothing.
    await tapVisible(tester, find.byKey(const Key('save-monthly-plan')));
    expect(backend.payments.calls, isEmpty);

    await tester.tap(find.byKey(const Key('monthly-plan-edit')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('due-day-field')));
    await tester.tap(find.byKey(const Key('due-day-5')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('save-monthly-plan')));
    expect(backend.payments.calls, ['configure:group-1:300:5:fixedDay']);
    expect(find.text('يُستحق يوم 5 من كل شهر'), findsOneWidget);
  });

  testWidgets('selects each student join day for monthly payments', (
    tester,
  ) async {
    final backend = backendWith(records: [buildRecord()]);
    await openPayments(tester, backend);
    await tester.tap(find.byKey(const Key('monthly-plan-set-up')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('monthly-due-joinDay')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('due-day-field')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('payment-amount-field')),
      '200',
    );
    await tapVisible(tester, find.byKey(const Key('save-monthly-plan')));
    expect(backend.payments.calls, ['configure:group-1:200:1:joinDay']);
    expect(find.text('يُستحق شهريًا في يوم انضمام كل طالب'), findsOneWidget);
  });

  testWidgets('stops the monthly plan after confirmation', (tester) async {
    final backend = backendWith(plan: plan, records: [buildRecord()]);
    await openPayments(tester, backend);
    await tester.tap(find.byKey(const Key('monthly-plan-stop')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-stop-plan')));
    await tester.pumpAndSettle();

    expect(backend.payments.calls, ['stop:group-1']);
    expect(find.text('لا يوجد اشتراك شهري نشط.'), findsOneWidget);
    expect(find.text('سارة أحمد'), findsOneWidget);
  });

  testWidgets('creates a one-time amount with a required title', (
    tester,
  ) async {
    final backend = backendWith();
    await openPayments(tester, backend);
    await openRoute(tester, OneTimePaymentRoute(groupId: 'group-1'));
    expect(find.byType(OneTimePaymentScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-one-time-payment')));
    await tester.pumpAndSettle();
    expect(find.text('أدخل عنوانًا.'), findsOneWidget);
    expect(find.text('أدخل المبلغ.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('one-time-payment-title')),
      'رسوم امتحان',
    );
    await tester.enterText(find.byKey(const Key('payment-amount-field')), '80');
    await tester.tap(find.byKey(const Key('create-one-time-payment')));
    await tester.pumpAndSettle();

    expect(backend.payments.calls, ['oneTime:group-1:80']);
    expect(backend.payments.oneTimeDrafts.single.description, isNull);
    expect(find.byType(GroupPaymentsScreen), findsOneWidget);
    expect(find.text('رسوم امتحان'), findsNWidgets(2));
  });

  testWidgets('suspended groups add nothing new but can mark records', (
    tester,
  ) async {
    final backend = backendWith(
      suspended: true,
      plan: plan,
      records: [buildRecord()],
    );
    await openPayments(tester, backend);

    expect(find.byKey(const Key('payments-suspended-notice')), findsOneWidget);
    expect(find.byKey(const Key('add-payment')), findsNothing);
    expect(find.byKey(const Key('monthly-plan-stop')), findsOneWidget);
    expect(find.byKey(const Key('mark-paid-o1')), findsOneWidget);

    await openRoute(tester, OneTimePaymentRoute(groupId: 'group-1'));
    expect(find.byKey(const Key('group-suspended-gate')), findsOneWidget);
    expect(find.byKey(const Key('create-one-time-payment')), findsNothing);

    await openRoute(tester, OneTimeSessionRoute(groupId: 'group-1'));
    expect(find.byKey(const Key('group-suspended-gate')), findsOneWidget);
    expect(find.byKey(const Key('create-one-time-session')), findsNothing);
  });

  testWidgets('a suspended group cannot start a new monthly plan', (
    tester,
  ) async {
    await openPayments(tester, backendWith(suspended: true));
    expect(find.byKey(const Key('monthly-plan-set-up')), findsNothing);
    await openRoute(tester, MonthlyPlanRoute(groupId: 'group-1'));
    expect(find.byKey(const Key('payments-new-blocked')), findsOneWidget);
    expect(find.byKey(const Key('save-monthly-plan')), findsNothing);
  });

  testWidgets('archived groups are history-only', (tester) async {
    await openPayments(
      tester,
      backendWith(
        archived: true,
        plan: plan,
        records: [
          buildRecord(),
          buildRecord(id: 'o2', status: PaymentStatus.paid),
        ],
      ),
    );

    expect(find.byKey(const Key('payments-archived-notice')), findsOneWidget);
    expect(find.text('سارة أحمد'), findsOneWidget);
    for (final key in [
      'add-payment',
      'mark-paid-o1',
      'monthly-plan-edit',
      'monthly-plan-stop',
    ]) {
      expect(find.byKey(Key(key)), findsNothing);
    }
    await tester.tap(find.byKey(const Key('payments-filter-paid')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('void-paid-o2')), findsNothing);
  });
}
