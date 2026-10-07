import 'package:flutter/foundation.dart';

/// Why typed text is not a valid EGP amount.
enum EgpAmountIssue { empty, invalid, tooManyDecimals, notPositive, tooLarge }

/// A positive Egyptian-pound amount with at most two decimal places, held
/// as whole piasters so no floating-point rounding reaches the backend.
@immutable
final class EgpAmount implements Comparable<EgpAmount> {
  const EgpAmount.piasters(this.piasters);

  static const zero = EgpAmount.piasters(0);

  /// `numeric(12,2)` upper bound accepted by the payment RPCs.
  static const maxPiasters = 999999999999;

  final int piasters;

  /// Parses typed text. Accepts Arabic-Indic digits, `٫` or `.` as the
  /// decimal separator, and thousands separators.
  static ({EgpAmount? amount, EgpAmountIssue? issue}) parse(String? text) {
    final normalized = _normalizeDigits(text ?? '')
        .trim()
        .replaceAll(RegExp(r'[,،٬\s]'), '');
    if (normalized.isEmpty) return (amount: null, issue: EgpAmountIssue.empty);
    final match = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(normalized);
    if (match == null) return (amount: null, issue: EgpAmountIssue.invalid);
    final fraction = match.group(2) ?? '';
    if (fraction.length > 2) {
      return (amount: null, issue: EgpAmountIssue.tooManyDecimals);
    }
    final pounds = match.group(1)!.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (pounds.length > 10) {
      return (amount: null, issue: EgpAmountIssue.tooLarge);
    }
    final piasters =
        int.parse(pounds) * 100 + int.parse(fraction.padRight(2, '0'));
    if (piasters <= 0) return (amount: null, issue: EgpAmountIssue.notPositive);
    if (piasters > maxPiasters) {
      return (amount: null, issue: EgpAmountIssue.tooLarge);
    }
    return (amount: EgpAmount.piasters(piasters), issue: null);
  }

  /// Reads a PostgREST `numeric` value, which arrives as a JSON number or,
  /// for large values, a string.
  factory EgpAmount.fromBackend(Object? value) {
    final text = switch (value) {
      final num number => number.toStringAsFixed(2),
      final String string => string,
      _ => throw FormatException('Missing EGP amount', value),
    };
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?0*$').firstMatch(text.trim());
    if (match == null) throw FormatException('Invalid EGP amount', value);
    return EgpAmount.piasters(
      int.parse(match.group(1)!) * 100 +
          int.parse((match.group(2) ?? '').padRight(2, '0')),
    );
  }

  /// The RPC `numeric` argument. A JSON number with at most two decimals
  /// keeps its exact decimal text, such as `1250.5`.
  num toBackend() =>
      piasters % 100 == 0 ? piasters ~/ 100 : num.parse(plainText);

  /// Ungrouped text for an edit field, such as `1250` or `1250.50`.
  String get plainText {
    final pounds = piasters ~/ 100;
    final fraction = piasters % 100;
    return fraction == 0
        ? '$pounds'
        : '$pounds.${fraction.toString().padLeft(2, '0')}';
  }

  /// Grouped display text without currency, such as `1,250` or `1,250.50`.
  /// Applications add the localized currency label.
  String get displayText {
    final pounds = (piasters ~/ 100).toString();
    final grouped = pounds.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+$)'),
      (_) => ',',
    );
    final fraction = piasters % 100;
    return fraction == 0
        ? grouped
        : '$grouped.${fraction.toString().padLeft(2, '0')}';
  }

  EgpAmount operator +(EgpAmount other) =>
      EgpAmount.piasters(piasters + other.piasters);

  @override
  int compareTo(EgpAmount other) => piasters.compareTo(other.piasters);

  @override
  bool operator ==(Object other) =>
      other is EgpAmount && other.piasters == piasters;

  @override
  int get hashCode => piasters.hashCode;

  @override
  String toString() => 'EgpAmount($plainText)';

  static String _normalizeDigits(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      buffer.write(switch (rune) {
        >= 0x0660 && <= 0x0669 => String.fromCharCode(rune - 0x0660 + 0x30),
        >= 0x06F0 && <= 0x06F9 => String.fromCharCode(rune - 0x06F0 + 0x30),
        0x066B => '.',
        _ => String.fromCharCode(rune),
      });
    }
    return buffer.toString();
  }
}
