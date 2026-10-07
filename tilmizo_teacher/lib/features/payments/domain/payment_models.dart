import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

enum MonthlyDueMode { fixedDay, joinDay }

/// The single active `monthly_payment_plans` row of a group. Changing its
/// amount or due day affects only newly generated months.
@immutable
final class MonthlyPaymentPlan {
  const MonthlyPaymentPlan({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.startedMonth,
    this.dueDay = 1,
    this.dueMode = MonthlyDueMode.fixedDay,
  });

  static const minDueDay = 1;
  static const maxDueDay = 31;

  final String id;
  final String groupId;
  final EgpAmount amount;

  /// Cairo-calendar day of each month the amount is due, 1 through 31.
  /// Shorter months clamp to their last day.
  final int dueDay;
  final MonthlyDueMode dueMode;

  /// First Cairo-calendar day of the month the plan started.
  final DateTime startedMonth;
}

/// A student obligation with the student's display identity.
@immutable
final class StudentPaymentRecord {
  const StudentPaymentRecord({
    required this.obligation,
    this.studentName,
    this.studentPhone,
  });

  final PaymentObligation obligation;
  final String? studentName;
  final String? studentPhone;
}

/// Everything the group payments screen shows. [records] contain only
/// current (unpaid or paid) obligations, newest first.
@immutable
final class GroupPayments {
  const GroupPayments({required this.records, this.plan});

  final MonthlyPaymentPlan? plan;
  final List<StudentPaymentRecord> records;

  PaymentTotals get totals =>
      PaymentTotals.of(records.map((record) => record.obligation));

  bool get isEmpty => plan == null && records.isEmpty;
}

/// A group-wide one-time amount for every active student.
@immutable
final class OneTimePaymentDraft {
  const OneTimePaymentDraft({
    required this.title,
    required this.amount,
    this.description,
  });

  static const maxTitleLength = 200;
  static const maxDescriptionLength = 5000;

  final String title;
  final String? description;
  final EgpAmount amount;
}
