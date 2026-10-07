/// Backend values shared by the teacher and student payment-record flows.
///
/// Telmizo records expected EGP amounts and teacher-confirmed full payments;
/// it never collects money. Every parser throws [FormatException] for an
/// unknown value instead of guessing.
library;

/// `payment_obligations.source_type`.
enum PaymentSourceType {
  monthly('monthly'),
  session('session'),
  oneTime('one_time');

  const PaymentSourceType(this.backendValue);

  final String backendValue;

  static PaymentSourceType fromBackend(String value) =>
      _parse(values, value, (type) => type.backendValue, 'payment source');
}

/// `payment_obligations.status`. A [voided] row is history, never an amount
/// currently due.
enum PaymentStatus {
  unpaid('unpaid'),
  paid('paid'),
  voided('void');

  const PaymentStatus(this.backendValue);

  final String backendValue;

  /// The statuses shown as current records.
  static const current = [unpaid, paid];

  static PaymentStatus fromBackend(String value) =>
      _parse(values, value, (status) => status.backendValue, 'payment status');
}

/// The `p_method` values accepted by `mark_payment_paid`.
enum PaymentMethod {
  cash('cash'),
  instapay('instapay'),
  wallet('wallet'),
  bankTransfer('bank_transfer'),
  other('other');

  const PaymentMethod(this.backendValue);

  final String backendValue;

  static PaymentMethod fromBackend(String value) =>
      _parse(values, value, (method) => method.backendValue, 'payment method');
}

T _parse<T>(
  List<T> values,
  String value,
  String Function(T) backendValue,
  String name,
) {
  for (final candidate in values) {
    if (backendValue(candidate) == value) return candidate;
  }
  throw FormatException('Unknown $name', value);
}
