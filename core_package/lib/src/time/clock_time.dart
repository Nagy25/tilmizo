/// A wall-clock time of day without a date or time zone.
///
/// Mirrors a Postgres `time without time zone` value such as `17:30:00`.
final class ClockTime implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// Parses `HH:mm` or `HH:mm:ss`; throws [FormatException] otherwise.
  factory ClockTime.fromBackend(String value) {
    final parts = value.split(':');
    if (parts.length < 2 || parts.length > 3) {
      throw FormatException('Invalid time', value);
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      throw FormatException('Invalid time', value);
    }
    if (hour < 0 || minute < 0) throw FormatException('Invalid time', value);
    return ClockTime(hour, minute);
  }

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  String get backendValue => '${_twoDigits(hour)}:${_twoDigits(minute)}:00';

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  int compareTo(ClockTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  bool isBefore(ClockTime other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'ClockTime($backendValue)';
}
