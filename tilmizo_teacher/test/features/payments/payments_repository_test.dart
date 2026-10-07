import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_teacher/features/payments/data/payments_dto.dart';
import 'package:tilmizo_teacher/features/payments/data/payments_remote_data_source.dart';
import 'package:tilmizo_teacher/features/payments/data/payments_repository_impl.dart';
import 'package:tilmizo_teacher/features/payments/domain/payment_models.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> obligationRow({
  String id = 'o1',
  String status = 'paid',
  Object? membership = const {
    'student': {'full_name': ' سارة أحمد ', 'phone': '+201000000001'},
  },
}) => {
  'id': id,
  'group_id': 'g1',
  'student_id': 's1',
  'source_type': 'session',
  'period_month': null,
  'title': 'Session payment',
  'description': null,
  'amount': 120.5,
  'due_on': '2026-10-05',
  'status': status,
  'membership': membership,
  'receipts': [
    {
      'id': 'r-voided',
      'method': 'cash',
      'recorded_at': '2026-10-05T10:00:00Z',
      'voided_at': '2026-10-05T11:00:00Z',
    },
    {
      'id': 'r-active',
      'method': 'bank_transfer',
      'recorded_at': '2026-10-05T12:00:00Z',
      'voided_at': null,
    },
  ],
};

final class _FakeDataSource implements PaymentsRemoteDataSource {
  Map<String, dynamic>? plan;
  List<Map<String, dynamic>> obligations = [];
  Map<String, dynamic>? sessionItem;
  Object? rpcResult;
  Object? error;
  final rpcs = <(String, Map<String, dynamic>)>[];

  Future<T> _run<T>(T value) async {
    if (error case final error?) throw error;
    return value;
  }

  @override
  Future<Map<String, dynamic>?> fetchActivePlan(String groupId) => _run(plan);

  @override
  Future<List<Map<String, dynamic>>> fetchObligations(String groupId) =>
      _run(obligations);

  @override
  Future<Map<String, dynamic>?> fetchActiveSessionItem(String sessionId) =>
      _run(sessionItem);

  @override
  Future<Object?> rpc(String function, Map<String, dynamic> params) {
    rpcs.add((function, params));
    return _run(rpcResult);
  }
}

void main() {
  late _FakeDataSource source;
  late PaymentsRepositoryImpl repository;

  setUp(() {
    source = _FakeDataSource();
    repository = PaymentsRepositoryImpl(
      source,
      FakePhoneAuthService(signedIn: true),
    );
  });

  test('embeds receipts and the student through the membership key', () {
    expect(
      PaymentsDto.obligationColumns,
      contains('receipts:payment_receipts'),
    );
    expect(
      PaymentsDto.obligationColumns,
      contains('group_memberships!payment_obligations_membership_fkey'),
    );
  });

  test('maps the plan and records with the single active receipt', () async {
    source
      ..plan = {
        'id': 'p1',
        'group_id': 'g1',
        'amount': '300.00',
        'started_month': '2026-09-01',
      }
      ..obligations = [
        obligationRow(),
        obligationRow(id: 'o2', status: 'unpaid', membership: null),
      ];

    final payments = await repository.fetchGroupPayments('g1');
    expect(payments.plan?.amount, const EgpAmount.piasters(30000));
    expect(payments.plan?.startedMonth, DateTime.utc(2026, 9));
    expect(payments.plan?.dueDay, 1); // Pre-migration rows default to day 1.

    final paid = payments.records.first;
    expect(paid.studentName, 'سارة أحمد');
    expect(paid.obligation.dueOn, DateTime.utc(2026, 10, 5));
    expect(paid.obligation.receipt?.id, 'r-active');
    expect(paid.obligation.receipt?.method, PaymentMethod.bankTransfer);

    final unpaid = payments.records.last;
    expect(unpaid.studentName, isNull);
    expect(unpaid.obligation.receipt, isNull);

    // Two receipts on one paid record still count as one payment.
    expect(payments.totals.paidCount, 1);
    expect(payments.totals.paid, const EgpAmount.piasters(12050));
    expect(payments.totals.unpaid, const EgpAmount.piasters(12050));
  });

  test('every write uses its deployed RPC and named parameters', () async {
    source.rpcResult = {
      'id': 'p1',
      'group_id': 'g1',
      'amount': 250,
      'due_day': 31,
      'started_month': '2026-10-01',
    };
    final configured = await repository.configureMonthlyPlan(
      'g1',
      const EgpAmount.piasters(25000),
      dueDay: 31,
    );
    expect(configured.dueDay, 31);
    await repository.stopMonthlyPlan('g1');
    await repository.createOneTimePayment(
      'g1',
      const OneTimePaymentDraft(
        title: '  مذكرة  ',
        description: '   ',
        amount: EgpAmount.piasters(9950),
      ),
    );
    await repository.attachSessionPayment(
      'sess1',
      const EgpAmount.piasters(10000),
    );
    await repository.markPaid('o1', PaymentMethod.instapay);
    await repository.voidPaidMark('r1');

    expect(
      [
        for (final (name, params) in source.rpcs) [name, params],
      ],
      [
        [
          'configure_monthly_payment_plan',
          {
            'p_group_id': 'g1',
            'p_amount': 250,
            'p_due_day': 31,
            'p_due_mode': 'fixed_day',
          },
        ],
        [
          'stop_monthly_payment_plan',
          {'p_group_id': 'g1'},
        ],
        [
          'create_one_time_group_payment',
          {
            'p_group_id': 'g1',
            'p_title': 'مذكرة',
            'p_amount': 99.5,
            'p_description': null,
          },
        ],
        [
          'attach_session_payment',
          {'p_session_id': 'sess1', 'p_amount': 100},
        ],
        [
          'mark_payment_paid',
          {'p_obligation_id': 'o1', 'p_method': 'instapay'},
        ],
        [
          'void_paid_payment',
          {'p_receipt_id': 'r1'},
        ],
      ],
    );
  });

  test('rejects a due day outside 1–31 before calling the RPC', () async {
    for (final day in [0, 32]) {
      await expectLater(
        repository.configureMonthlyPlan(
          'g1',
          const EgpAmount.piasters(100),
          dueDay: day,
        ),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.type,
            'type',
            AppFailureType.invalidInput,
          ),
        ),
      );
    }
    expect(source.rpcs, isEmpty);
  });

  test('maps and sends a student join-day monthly plan', () async {
    source.rpcResult = {
      'id': 'p1',
      'group_id': 'g1',
      'amount': 250,
      'due_day': 1,
      'due_mode': 'join_day',
      'started_month': '2026-10-01',
    };
    final plan = await repository.configureMonthlyPlan(
      'g1',
      const EgpAmount.piasters(25000),
      dueDay: 1,
      dueMode: MonthlyDueMode.joinDay,
    );
    expect(plan.dueMode, MonthlyDueMode.joinDay);
    expect(source.rpcs.single.$2, {
      'p_group_id': 'g1',
      'p_amount': 250,
      'p_due_day': null,
      'p_due_mode': 'join_day',
    });
  });

  test('reads the active session amount or none', () async {
    expect(await repository.fetchSessionPaymentAmount('s1'), isNull);
    source.sessionItem = {'id': 'i1', 'amount': 75};
    expect(
      await repository.fetchSessionPaymentAmount('s1'),
      const EgpAmount.piasters(7500),
    );
  });

  test('maps backend rejections and bad rows to app failures', () async {
    source.error = const PostgrestException(
      message: 'A suspended group cannot start a new payment plan',
      code: '42501',
    );
    await expectLater(
      repository.configureMonthlyPlan(
        'g1',
        const EgpAmount.piasters(100),
        dueDay: 1,
      ),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.type,
          'type',
          AppFailureType.rejected,
        ),
      ),
    );

    source
      ..error = null
      ..obligations = [
        {...obligationRow(), 'status': 'partially_paid'},
      ];
    await expectLater(
      repository.fetchGroupPayments('g1'),
      throwsA(
        isA<AppFailure>().having((f) => f.type, 'type', AppFailureType.unknown),
      ),
    );
  });

  test('requires a signed-in teacher before any write', () async {
    final signedOut = PaymentsRepositoryImpl(source, FakePhoneAuthService());
    await expectLater(
      signedOut.markPaid('o1', PaymentMethod.cash),
      throwsA(isA<AppFailure>()),
    );
    expect(source.rpcs, isEmpty);
  });

  test('group payments are empty without a plan or records', () {
    expect(const GroupPayments(records: []).isEmpty, isTrue);
  });
}
