import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(CairoTime.ensureInitialized);

  test('converts Cairo wall time using winter and summer rules', () {
    expect(
      CairoTime.wallTimeToUtc(DateTime.utc(2026, 1, 15), 17, 0),
      DateTime.utc(2026, 1, 15, 15),
    );
    expect(
      CairoTime.wallTimeToUtc(DateTime.utc(2026, 7, 15), 17, 0),
      DateTime.utc(2026, 7, 15, 14),
    );
  });

  test('rejects wall times inside the spring-forward gap', () {
    expect(CairoTime.wallTimeToUtc(DateTime.utc(2026, 4, 24), 0, 30), isNull);
    expect(
      CairoTime.wallTimeToUtc(DateTime.utc(2026, 4, 24), 1, 30),
      DateTime.utc(2026, 4, 23, 22, 30),
    );
  });

  test('reports the Cairo calendar date of an instant', () {
    // 22:30 UTC in summer is already the next day in Cairo.
    expect(
      CairoTime.dateOf(DateTime.utc(2026, 7, 15, 22, 30)),
      DateTime.utc(2026, 7, 16),
    );
    expect(
      CairoTime.calendarDaysBetween(
        DateTime.utc(2026, 7, 15, 20),
        DateTime.utc(2026, 7, 15, 22, 30),
      ),
      1,
    );
  });

  test('round-trips through toCairo', () {
    final cairo = CairoTime.toCairo(DateTime.utc(2026, 10, 5, 9));
    expect([cairo.hour, cairo.minute], [12, 0]);
  });

  test('parses and formats backend clock times', () {
    const time = ClockTime(9, 5);
    expect(time.backendValue, '09:05:00');
    expect(ClockTime.fromBackend('17:30:00'), const ClockTime(17, 30));
    expect(ClockTime.fromBackend('17:30'), const ClockTime(17, 30));
    expect(time.isBefore(const ClockTime(9, 6)), isTrue);
    expect(() => ClockTime.fromBackend('24:00:00'), throwsFormatException);
    expect(() => ClockTime.fromBackend('noon'), throwsFormatException);
  });
}
