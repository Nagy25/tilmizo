/// Postgres `date` values as UTC-midnight calendar dates. They are never
/// converted between time zones: `2026-10-08` stays the 8th everywhere.
library;

/// Parses a Postgres `date` (`YYYY-MM-DD`) as a UTC midnight calendar value
/// without any time-zone conversion.
DateTime parseCalendarDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw FormatException('Invalid date', value);
  return DateTime.utc(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// Formats the calendar fields of [date] as `YYYY-MM-DD` for a `date`
/// parameter, ignoring its time and zone.
String formatCalendarDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-'
      '${two(date.month)}-${two(date.day)}';
}
