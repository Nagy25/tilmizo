/// Validation and normalization for Egyptian mobile numbers.
///
/// Accepted input shapes, after removing spaces and common separators:
/// `01XXXXXXXXX`, `1XXXXXXXXX`, `+201XXXXXXXXX`, and `00201XXXXXXXXX`.
/// Only the Vodafone (`10`), Etisalat (`11`), Orange (`12`), and WE (`15`)
/// operator prefixes are valid.
abstract final class EgyptianPhone {
  static const countryCode = '+20';

  static final RegExp _separators = RegExp(r'[\s\-(). ‎‏]');
  static final RegExp _nationalSignificant = RegExp(r'^1[0125][0-9]{8}$');
  static final RegExp _e164 = RegExp(r'^\+201[0125][0-9]{8}$');

  /// Returns the canonical E.164 form (`+201XXXXXXXXX`) or `null` when [input]
  /// is not a valid Egyptian mobile number.
  static String? normalize(String input) {
    var digits = _toAsciiDigits(input).replaceAll(_separators, '');

    if (digits.startsWith('+20')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0020')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (!_nationalSignificant.hasMatch(digits)) return null;
    return '$countryCode$digits';
  }

  static bool isValid(String input) => normalize(input) != null;

  /// Whether [value] is already canonical Egyptian E.164.
  static bool isE164(String value) => _e164.hasMatch(value);

  /// Masks an E.164 number for display, keeping the operator prefix and the
  /// last four digits: `+20 10 •••• 5678`.
  static String mask(String e164) {
    if (!isE164(e164)) return '••••';
    final national = e164.substring(3);
    return '+20 ${national.substring(0, 2)} •••• '
        '${national.substring(national.length - 4)}';
  }

  /// Formats an E.164 number in its readable local form: `010 1234 5678`.
  static String formatLocal(String e164) {
    if (!isE164(e164)) return e164;
    final local = '0${e164.substring(3)}';
    return '${local.substring(0, 3)} ${local.substring(3, 7)} '
        '${local.substring(7)}';
  }

  /// Converts Arabic-Indic and Eastern Arabic-Indic digits to ASCII digits so
  /// numbers typed with an Arabic keyboard are accepted.
  static String _toAsciiDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
