import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:tilmizo_teacher/features/payments/domain/payment_models.dart';
import 'package:tilmizo_teacher/features/payments/domain/payments_repository.dart';

import 'fakes.dart';

EgpAmount egp(num pounds) => EgpAmount.piasters((pounds * 100).round());

StudentPaymentRecord buildRecord({
  String id = 'o1',
  String groupId = 'group-1',
  String? studentName = 'سارة أحمد',
  PaymentSourceType source = PaymentSourceType.oneTime,
  String title = 'مذكرة الفصل الأول',
  num amount = 150,
  PaymentStatus status = PaymentStatus.unpaid,
  DateTime? dueOn,
  PaymentMethod method = PaymentMethod.cash,
}) {
  final due = dueOn ?? DateTime.utc(2026, 10, 1);
  return StudentPaymentRecord(
    studentName: studentName,
    obligation: PaymentObligation(
      id: id,
      groupId: groupId,
      studentId: 'student-$id',
      sourceType: source,
      title: title,
      amount: egp(amount),
      dueOn: due,
      periodMonth: source == PaymentSourceType.monthly ? due : null,
      status: status,
      receipt: status == PaymentStatus.paid
          ? PaymentReceipt(
              id: 'receipt-$id',
              method: method,
              recordedAt: DateTime.utc(2026, 10, 2, 8),
            )
          : null,
    ),
  );
}

/// In-memory [PaymentsRepository] following the RPC contract: full payments
/// only, voided marks return records to unpaid, and amounts reach every
/// student in [students].
final class FakePaymentsRepository implements PaymentsRepository {
  FakePaymentsRepository({List<StudentPaymentRecord>? records, this.plan})
    : records = [...?records];

  final List<StudentPaymentRecord> records;
  MonthlyPaymentPlan? plan;
  final sessionAmounts = <String, EgpAmount>{};
  final students = <String>['سارة أحمد', 'عمر خالد'];
  final calls = <String>[];
  final oneTimeDrafts = <OneTimePaymentDraft>[];
  AppFailure? fetchFailure;
  AppFailure? mutationFailure;
  Completer<void>? pendingMutation;
  int fetches = 0;
  int _nextId = 100;

  @override
  Future<GroupPayments> fetchGroupPayments(String groupId) async {
    fetches++;
    if (fetchFailure case final failure?) throw failure;
    return GroupPayments(
      plan: plan?.groupId == groupId ? plan : null,
      records: [
        for (final record in records)
          if (record.obligation.groupId == groupId &&
              record.obligation.status != PaymentStatus.voided)
            record,
      ],
    );
  }

  @override
  Future<EgpAmount?> fetchSessionPaymentAmount(String sessionId) async {
    if (fetchFailure case final failure?) throw failure;
    return sessionAmounts[sessionId];
  }

  @override
  Future<MonthlyPaymentPlan> configureMonthlyPlan(
    String groupId,
    EgpAmount amount, {
    required int dueDay,
    MonthlyDueMode dueMode = MonthlyDueMode.fixedDay,
  }) async {
    await _write(
      'configure:$groupId:${amount.plainText}:$dueDay:${dueMode.name}',
    );
    final current = plan;
    return plan = MonthlyPaymentPlan(
      id: current?.id ?? 'plan-1',
      groupId: groupId,
      amount: amount,
      dueDay: dueDay,
      dueMode: dueMode,
      startedMonth: current?.startedMonth ?? DateTime.utc(2026, 10),
    );
  }

  @override
  Future<void> stopMonthlyPlan(String groupId) async {
    await _write('stop:$groupId');
    plan = null;
  }

  @override
  Future<void> createOneTimePayment(
    String groupId,
    OneTimePaymentDraft draft,
  ) async {
    await _write('oneTime:$groupId:${draft.amount.plainText}');
    oneTimeDrafts.add(draft);
    for (final student in students) {
      records.add(
        buildRecord(
          id: 'o${_nextId++}',
          groupId: groupId,
          studentName: student,
          title: draft.title,
          amount: draft.amount.piasters / 100,
          dueOn: testTime,
        ),
      );
    }
  }

  @override
  Future<void> attachSessionPayment(String sessionId, EgpAmount amount) async {
    await _write('attach:$sessionId:${amount.plainText}');
    if (sessionAmounts.containsKey(sessionId)) {
      throw const AppFailure(AppFailureType.rejected);
    }
    sessionAmounts[sessionId] = amount;
  }

  @override
  Future<void> markPaid(String obligationId, PaymentMethod method) async {
    await _write('markPaid:$obligationId:${method.backendValue}');
    _replace(obligationId, PaymentStatus.paid, method);
  }

  @override
  Future<void> voidPaidMark(String receiptId) async {
    await _write('void:$receiptId');
    final record = records.firstWhere(
      (r) => r.obligation.receipt?.id == receiptId,
    );
    _replace(record.obligation.id, PaymentStatus.unpaid, null);
  }

  void _replace(String id, PaymentStatus status, PaymentMethod? method) {
    final index = records.indexWhere((r) => r.obligation.id == id);
    final old = records[index].obligation;
    records[index] = buildRecord(
      id: id,
      groupId: old.groupId,
      studentName: records[index].studentName,
      source: old.sourceType,
      title: old.title,
      amount: old.amount.piasters / 100,
      status: status,
      dueOn: old.dueOn,
      method: method ?? PaymentMethod.cash,
    );
  }

  Future<void> _write(String call) async {
    calls.add(call);
    await pendingMutation?.future;
    if (mutationFailure case final failure?) throw failure;
  }
}
