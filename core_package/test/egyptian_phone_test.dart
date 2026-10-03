import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EgyptianPhone.normalize', () {
    test('accepts local, national, and international shapes', () {
      expect(EgyptianPhone.normalize('01012345678'), '+201012345678');
      expect(EgyptianPhone.normalize('1012345678'), '+201012345678');
      expect(EgyptianPhone.normalize('+201012345678'), '+201012345678');
      expect(EgyptianPhone.normalize('00201012345678'), '+201012345678');
    });

    test('accepts every Egyptian operator prefix', () {
      for (final prefix in ['10', '11', '12', '15']) {
        expect(
          EgyptianPhone.normalize('0${prefix}12345678'),
          '+20${prefix}12345678',
          reason: 'prefix $prefix',
        );
      }
    });

    test('removes spaces and common separators', () {
      expect(EgyptianPhone.normalize('010 1234 5678'), '+201012345678');
      expect(EgyptianPhone.normalize('010-1234-5678'), '+201012345678');
      expect(EgyptianPhone.normalize('(010) 1234.5678'), '+201012345678');
      expect(EgyptianPhone.normalize('+20 115 123 4567'), '+201151234567');
      expect(EgyptianPhone.normalize(' 0122 1234567 '), '+201221234567');
    });

    test('accepts Arabic-Indic digits', () {
      expect(EgyptianPhone.normalize('٠١٠١٢٣٤٥٦٧٨'), '+201012345678');
      expect(EgyptianPhone.normalize('۰۱۵۱۲۳۴۵۶۷۸'), '+201512345678');
    });

    test('rejects malformed and non-Egyptian numbers', () {
      const invalid = [
        '',
        '0101234567', // too short
        '010123456789', // too long
        '01312345678', // unknown operator
        '01412345678',
        '01612345678',
        '0201012345678', // landline-style prefix
        '+966501234567', // Saudi
        '+2010123456', // short international
        '+21012345678', // missing country digit
        '010abc45678',
        '++201012345678',
        '0021012345678',
      ];
      for (final value in invalid) {
        expect(EgyptianPhone.normalize(value), isNull, reason: value);
        expect(EgyptianPhone.isValid(value), isFalse, reason: value);
      }
    });
  });

  test('isE164 accepts only canonical numbers', () {
    expect(EgyptianPhone.isE164('+201012345678'), isTrue);
    expect(EgyptianPhone.isE164('01012345678'), isFalse);
    expect(EgyptianPhone.isE164('+201312345678'), isFalse);
  });

  test('mask hides the middle digits', () {
    expect(EgyptianPhone.mask('+201012345678'), '+20 10 •••• 5678');
    expect(EgyptianPhone.mask('bad'), '••••');
  });

  test('formatLocal produces readable local form', () {
    expect(EgyptianPhone.formatLocal('+201012345678'), '010 1234 5678');
  });
}
