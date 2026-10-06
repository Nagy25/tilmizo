import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Africa/Cairo calendar helpers backed by the IANA time-zone database.
///
/// Class schedules are stored as Cairo wall-clock times, and Egypt observes
/// daylight saving time, so conversions must use the zone rules instead of a
/// fixed offset. Call [ensureInitialized] once before using the other members.
abstract final class CairoTime {
  static const zoneName = 'Africa/Cairo';

  static tz.Location? _location;

  /// Loads the bundled time-zone database. Safe to call more than once.
  static void ensureInitialized() {
    if (_location != null) return;
    tz_data.initializeTimeZones();
    _location = tz.getLocation(zoneName);
  }

  static tz.Location get location {
    final location = _location;
    if (location == null) {
      throw StateError('CairoTime.ensureInitialized() was not called');
    }
    return location;
  }

  /// The Cairo wall-clock representation of [instant].
  static tz.TZDateTime toCairo(DateTime instant) =>
      tz.TZDateTime.from(instant, location);

  /// The Cairo calendar date of [instant] as a UTC midnight date value.
  static DateTime dateOf(DateTime instant) {
    final cairo = toCairo(instant);
    return DateTime.utc(cairo.year, cairo.month, cairo.day);
  }

  /// Converts a Cairo calendar [date] and wall-clock time to a UTC instant.
  ///
  /// Returns null when the wall-clock time does not exist on that date, such
  /// as during the spring-forward daylight-saving gap.
  static DateTime? wallTimeToUtc(DateTime date, int hour, int minute) {
    final cairo = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    final exists =
        cairo.year == date.year &&
        cairo.month == date.month &&
        cairo.day == date.day &&
        cairo.hour == hour &&
        cairo.minute == minute;
    return exists ? cairo.toUtc() : null;
  }

  /// Whole calendar days from [from]'s Cairo date to [to]'s Cairo date.
  static int calendarDaysBetween(DateTime from, DateTime to) =>
      dateOf(to).difference(dateOf(from)).inDays;
}
