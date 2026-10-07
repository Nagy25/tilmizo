import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({
  String status = 'paid',
  Object amount = 150.5,
  List<Map<String, dynamic>> receipts = const [],
}) => {
  'id': 'o1',
  'group_id': 'g1',
  'student_id': 's1',
  'source_type': 'monthly',
  'period_month': '2026-10-01',
  'title': 'Monthly payment',
  'description': null,
  'amount': amount,
  'due_on': '2026-10-01',
  'status': status,
  'receipts': receipts,
};

void main() {
  group('EgpAmount', () {
    test('accepts two-decimal input in Western or Arabic digits', () {
      expect(EgpAmount.parse('150').amount, const EgpAmount.piasters(15000));
      expect(
        EgpAmount.parse('1,250.5').amount,
        const EgpAmount.piasters(125050),
      );
      expect(EgpAmount.parse('١٢٠٫٧٥').amount, const EgpAmount.piasters(12075));
      expect(EgpAmount.parse(' 0.01 ').amount, const EgpAmount.piasters(1));
    });

    test('reports why text is not a valid amount', () {
      expect(EgpAmount.parse('').issue, EgpAmountIssue.empty);
      expect(EgpAmount.parse('abc').issue, EgpAmountIssue.invalid);
      expect(EgpAmount.parse('-5').issue, EgpAmountIssue.invalid);
      expect(EgpAmount.parse('10.123').issue, EgpAmountIssue.tooManyDecimals);
      expect(EgpAmount.parse('0').issue, EgpAmountIssue.notPositive);
      expect(EgpAmount.parse('0.00').issue, EgpAmountIssue.notPositive);
      expect(EgpAmount.parse('99999999999').issue, EgpAmountIssue.tooLarge);
      expect(
        EgpAmount.parse('9999999999.99').amount,
        const EgpAmount.piasters(EgpAmount.maxPiasters),
      );
    });

    test('formats for display, editing and RPC arguments', () {
      const amount = EgpAmount.piasters(125050);
      expect(amount.displayText, '1,250.50');
      expect(amount.plainText, '1250.50');
      expect(amount.toBackend(), 1250.5);
      expect(const EgpAmount.piasters(1000000).displayText, '10,000');
      expect(const EgpAmount.piasters(1000000).toBackend(), 10000);
    });

    test('reads numeric values from numbers or strings', () {
      expect(EgpAmount.fromBackend(150), const EgpAmount.piasters(15000));
      expect(EgpAmount.fromBackend(0.1), const EgpAmount.piasters(10));
      expect(EgpAmount.fromBackend('99.90'), const EgpAmount.piasters(9990));
      expect(() => EgpAmount.fromBackend(null), throwsFormatException);
      expect(() => EgpAmount.fromBackend('1.234'), throwsFormatException);
    });
  });

  test('maps exact backend values and rejects unknown ones', () {
    expect(PaymentMethod.values.map((m) => m.backendValue), [
      'cash',
      'instapay',
      'wallet',
      'bank_transfer',
      'other',
    ]);
    expect(PaymentStatus.fromBackend('void'), PaymentStatus.voided);
    expect(
      PaymentSourceType.fromBackend('one_time'),
      PaymentSourceType.oneTime,
    );
    expect(() => PaymentMethod.fromBackend('card'), throwsFormatException);
    expect(() => PaymentStatus.fromBackend('partial'), throwsFormatException);
  });

  test('parses a row with Cairo calendar dates and the active receipt', () {
    final obligation = PaymentObligation.fromRow(
      _row(
        receipts: [
          {
            'id': 'r-old',
            'method': 'cash',
            'recorded_at': '2026-10-02T08:00:00Z',
            'voided_at': '2026-10-03T08:00:00Z',
          },
          {
            'id': 'r-new',
            'method': 'instapay',
            'recorded_at': '2026-10-04T08:00:00+00:00',
            'voided_at': null,
          },
        ],
      ),
    );
    expect(obligation.dueOn, DateTime.utc(2026, 10));
    expect(obligation.periodMonth, DateTime.utc(2026, 10));
    expect(obligation.amount, const EgpAmount.piasters(15050));
    expect(obligation.receipt?.id, 'r-new');
    expect(obligation.receipt?.method, PaymentMethod.instapay);
  });

  test('an unpaid row ignores voided historical receipts', () {
    final obligation = PaymentObligation.fromRow(
      _row(
        status: 'unpaid',
        receipts: [
          {
            'id': 'r1',
            'method': 'cash',
            'recorded_at': '2026-10-02T08:00:00Z',
            'voided_at': '2026-10-03T08:00:00Z',
          },
        ],
      ),
    );
    expect(obligation.receipt, isNull);
    expect(
      () => PaymentObligation.fromRow({..._row(), 'id': null}),
      throwsFormatException,
    );
  });

  test('totals exclude void rows and count each paid record once', () {
    final receipts = [
      {
        'id': 'a',
        'method': 'cash',
        'recorded_at': '2026-10-02T08:00:00Z',
        'voided_at': '2026-10-02T09:00:00Z',
      },
      {
        'id': 'b',
        'method': 'cash',
        'recorded_at': '2026-10-02T10:00:00Z',
        'voided_at': null,
      },
    ];
    final totals = PaymentTotals.of([
      PaymentObligation.fromRow(_row(amount: 100, receipts: receipts)),
      PaymentObligation.fromRow(_row(status: 'unpaid', amount: 50)),
      PaymentObligation.fromRow(_row(status: 'void', amount: 999)),
    ]);
    expect(totals.paid, const EgpAmount.piasters(10000));
    expect(totals.unpaid, const EgpAmount.piasters(5000));
    expect(totals.paidCount, 1);
    expect(totals.unpaidCount, 1);
    expect(totals.expected, const EgpAmount.piasters(15000));
  });
}
