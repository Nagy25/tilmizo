import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tilmizo_student/features/payments/data/student_payments_repository_impl.dart';

import '../../helpers/fakes.dart';

Map<String, dynamic> _row({
  String id = 'o1',
  String studentId = testUserId,
  String status = 'paid',
}) => {
  'id': id,
  'group_id': 'g1',
  'student_id': studentId,
  'source_type': 'monthly',
  'period_month': '2026-10-01',
  'title': 'Monthly payment',
  'description': null,
  'amount': '250.00',
  'due_on': '2026-10-01',
  'status': status,
  'receipts': [
    {
      'id': 'r1',
      'method': 'wallet',
      'recorded_at': '2026-10-03T07:30:00Z',
      'voided_at': null,
    },
  ],
};

final class _FakeDataSource implements StudentPaymentsRemoteDataSource {
  List<Map<String, dynamic>> rows = [];
  Object? error;
  ({String studentId, String? groupId})? lastQuery;

  @override
  Future<List<Map<String, dynamic>>> fetchObligations({
    required String studentId,
    String? groupId,
  }) async {
    lastQuery = (studentId: studentId, groupId: groupId);
    if (error case final error?) throw error;
    return rows;
  }
}

void main() {
  late _FakeDataSource source;
  late StudentPaymentsRepositoryImpl repository;

  setUp(() {
    source = _FakeDataSource();
    repository = StudentPaymentsRepositoryImpl(
      source,
      FakePhoneAuthService(signedIn: true),
    );
  });

  test('queries only the signed-in student, optionally by group', () async {
    source.rows = [_row()];
    final payments = await repository.fetchMyPayments(groupId: 'g1');

    expect(source.lastQuery, (studentId: testUserId, groupId: 'g1'));
    expect(payments.single.amount, const EgpAmount.piasters(25000));
    expect(payments.single.periodMonth, DateTime.utc(2026, 10));
    expect(payments.single.receipt?.method, PaymentMethod.wallet);

    await repository.fetchMyPayments();
    expect(source.lastQuery, (studentId: testUserId, groupId: null));
  });

  test('never shows another student or a void row', () async {
    source.rows = [
      _row(),
      _row(id: 'other', studentId: 'student-2'),
      _row(id: 'void', status: 'void'),
    ];
    final payments = await repository.fetchMyPayments();
    expect(payments.map((p) => p.id), ['o1']);
  });

  test('requires a signed-in student', () async {
    final signedOut = StudentPaymentsRepositoryImpl(
      source,
      FakePhoneAuthService(),
    );
    await expectLater(signedOut.fetchMyPayments(), throwsA(isA<AppFailure>()));
    expect(source.lastQuery, isNull);
  });

  test('maps backend errors and malformed rows to app failures', () async {
    source.error = const PostgrestException(
      message: 'expired',
      code: 'PGRST301',
    );
    await expectLater(
      repository.fetchMyPayments(),
      throwsA(
        isA<AppFailure>().having(
          (f) => f.type,
          'type',
          AppFailureType.sessionExpired,
        ),
      ),
    );

    source
      ..error = null
      ..rows = [
        {..._row(), 'amount': 'free'},
      ];
    await expectLater(
      repository.fetchMyPayments(),
      throwsA(
        isA<AppFailure>().having((f) => f.type, 'type', AppFailureType.unknown),
      ),
    );
  });
}
