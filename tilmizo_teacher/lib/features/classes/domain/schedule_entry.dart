import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

import 'session_location.dart';

/// One weekly slot of a group's schedule in Cairo wall-clock time.
///
/// The backend generates sessions from active slots for a rolling 28-day
/// window; editing a slot never changes sessions that already exist.
@immutable
final class WeeklySlot {
  const WeeklySlot({
    required this.weekday,
    required this.start,
    required this.end,
    required this.location,
  });

  /// ISO weekday: 1 is Monday and 7 is Sunday.
  final int weekday;
  final ClockTime start;
  final ClockTime end;
  final SessionLocation location;

  bool get hasValidTimes => start.isBefore(end);

  bool sameTimeAs(WeeklySlot other) =>
      other.weekday == weekday && other.start == start && other.end == end;

  @override
  bool operator ==(Object other) =>
      other is WeeklySlot &&
      other.weekday == weekday &&
      other.start == start &&
      other.end == end &&
      other.location == location;

  @override
  int get hashCode => Object.hash(weekday, start, end, location);
}

/// A saved weekly slot.
@immutable
final class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.groupId,
    required this.slot,
    required this.isActive,
  });

  final String id;
  final String groupId;
  final WeeklySlot slot;
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      other is ScheduleEntry &&
      other.id == id &&
      other.groupId == groupId &&
      other.slot == slot &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, groupId, slot, isActive);
}

/// The schedule already has an active slot with the same day and times.
final class ScheduleConflict implements Exception {
  const ScheduleConflict();
}
