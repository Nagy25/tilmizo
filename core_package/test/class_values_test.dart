import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses every known backend value', () {
    for (final status in SessionStatus.values) {
      expect(SessionStatus.fromBackend(status.backendValue), status);
    }
    for (final status in AttendanceStatus.values) {
      expect(AttendanceStatus.fromBackend(status.backendValue), status);
    }
    for (final type in SessionLocationType.values) {
      expect(SessionLocationType.fromBackend(type.backendValue), type);
    }
    expect(
      AttendanceStatus.fromBackend('not_marked'),
      AttendanceStatus.notMarked,
    );
  });

  test('rejects unknown values instead of guessing', () {
    expect(() => SessionStatus.fromBackend('postponed'), throwsFormatException);
    expect(
      () => AttendanceStatus.fromBackend('Present'),
      throwsFormatException,
    );
    expect(
      () => SessionLocationType.fromBackend('hybrid'),
      throwsFormatException,
    );
  });
}
