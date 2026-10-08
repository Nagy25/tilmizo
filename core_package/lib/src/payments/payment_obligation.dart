import 'package:flutter/foundation.dart';

import '../time/calendar_date.dart';
import 'egp_amount.dart';
import 'payment_values.dart';

/// The active `payment_receipts` row of a paid obligation.
@immutable
final class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.method,
    required this.recordedAt,
  });

  final String id;
  final PaymentMethod method;
  final DateTime recordedAt;
}

/// One student's expected amount, as visible to the signed-in user under
/// RLS. Title, description and amount are snapshots taken when the record
/// was created.
@immutable
final class PaymentObligation {
  const PaymentObligation({
    required this.id,
    required this.groupId,
    required this.studentId,
    required this.sourceType,
    required this.title,
    required this.amount,
    required this.dueOn,
    required this.status,
    this.description,
    this.periodMonth,
    this.receipt,
  });

  /// Parses a Data API row selected with [columns]. Throws [FormatException]
  /// for a missing column or an unknown value.
  factory PaymentObligation.fromRow(Map<String, dynamic> row) {
    final status = PaymentStatus.fromBackend(_required(row, 'status'));
    return PaymentObligation(
      id: _required(row, 'id'),
      groupId: _required(row, 'group_id'),
      studentId: _required(row, 'student_id'),
      sourceType: PaymentSourceType.fromBackend(_required(row, 'source_type')),
      title: _required(row, 'title'),
      description: row['description'] as String?,
      amount: EgpAmount.fromBackend(row['amount']),
      dueOn: parseCalendarDate(_required(row, 'due_on')),
      periodMonth: switch (row['period_month']) {
        final String month => parseCalendarDate(month),
        _ => null,
      },
      status: status,
      receipt: status == PaymentStatus.paid
          ? activeReceipt(row['receipts'])
          : null,
    );
  }

  /// Obligation columns with every receipt embedded. Voided receipts stay
  /// for audit; [activeReceipt] picks the single one that counts.
  static const columns =
      'id, group_id, student_id, source_type, period_month, title, '
      'description, amount, due_on, status, '
      'receipts:payment_receipts(id, method, recorded_at, voided_at)';

  final String id;
  final String groupId;
  final String studentId;
  final PaymentSourceType sourceType;
  final String title;
  final String? description;
  final EgpAmount amount;

  /// The Cairo calendar date (UTC midnight value): the session day, the
  /// creation day of a one-time amount, or the first day of a month.
  final DateTime dueOn;

  /// First Cairo-calendar day of the month for monthly records.
  final DateTime? periodMonth;
  final PaymentStatus status;

  /// The active paid mark; null unless [status] is paid.
  final PaymentReceipt? receipt;

  bool get isPaid => status == PaymentStatus.paid;
  bool get isUnpaid => status == PaymentStatus.unpaid;

  /// The single unvoided receipt in [rows], newest first if the backend
  /// ever returned more than one. Historical voided receipts never count as
  /// additional payments.
  static PaymentReceipt? activeReceipt(Object? rows) {
    if (rows is! List) return null;
    PaymentReceipt? latest;
    for (final row in rows.cast<Map<String, dynamic>>()) {
      if (row['voided_at'] != null) continue;
      final receipt = PaymentReceipt(
        id: _required(row, 'id'),
        method: PaymentMethod.fromBackend(_required(row, 'method')),
        recordedAt: DateTime.parse(_required(row, 'recorded_at')).toUtc(),
      );
      if (latest == null || receipt.recordedAt.isAfter(latest.recordedAt)) {
        latest = receipt;
      }
    }
    return latest;
  }

  static String _required(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing payment column', key);
  }
}

/// Unpaid and paid totals of current records. Void rows are excluded, and
/// each paid obligation counts once however many receipts it has had.
@immutable
final class PaymentTotals {
  const PaymentTotals({
    required this.unpaid,
    required this.paid,
    required this.unpaidCount,
    required this.paidCount,
  });

  factory PaymentTotals.of(Iterable<PaymentObligation> obligations) {
    var unpaid = EgpAmount.zero;
    var paid = EgpAmount.zero;
    var unpaidCount = 0;
    var paidCount = 0;
    for (final obligation in obligations) {
      switch (obligation.status) {
        case PaymentStatus.unpaid:
          unpaid += obligation.amount;
          unpaidCount++;
        case PaymentStatus.paid:
          paid += obligation.amount;
          paidCount++;
        case PaymentStatus.voided:
          break;
      }
    }
    return PaymentTotals(
      unpaid: unpaid,
      paid: paid,
      unpaidCount: unpaidCount,
      paidCount: paidCount,
    );
  }

  final EgpAmount unpaid;
  final EgpAmount paid;
  final int unpaidCount;
  final int paidCount;

  EgpAmount get expected => unpaid + paid;
}
