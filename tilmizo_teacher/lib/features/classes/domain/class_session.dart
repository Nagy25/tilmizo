import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

import 'session_location.dart';

/// The group a session belongs to, as needed by session screens.
@immutable
final class SessionGroup {
  const SessionGroup({
    required this.id,
    required this.name,
    required this.isActive,
    this.subject,
    this.isSuspended = false,
  });

  final String id;
  final String name;
  final String? subject;

  /// Archived groups are inactive; their sessions are read-only history.
  final bool isActive;

  /// A paused group keeps its sessions but accepts no new payment amounts.
  final bool isSuspended;

  @override
  bool operator ==(Object other) =>
      other is SessionGroup &&
      other.isSuspended == isSuspended &&
      other.id == id &&
      other.name == name &&
      other.subject == subject &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, name, subject, isActive, isSuspended);
}

/// One class meeting. Location and times are a snapshot: later weekly
/// schedule edits never change an existing session.
@immutable
final class ClassSession {
  const ClassSession({
    required this.id,
    required this.group,
    required this.startsAt,
    required this.endsAt,
    required this.location,
    required this.status,
    this.scheduleEntryId,
    this.notes,
  });

  static const maxNotesLength = 5000;

  final String id;
  final SessionGroup group;
  final String? scheduleEntryId;
  final DateTime startsAt;
  final DateTime endsAt;
  final SessionLocation location;
  final SessionStatus status;
  final String? notes;

  bool get isRecurring => scheduleEntryId != null;
  bool get isCancelled => status == SessionStatus.cancelled;
  Duration get duration => endsAt.difference(startsAt);

  bool isUpcoming(DateTime now) =>
      status == SessionStatus.scheduled && endsAt.isAfter(now);

  bool isInProgress(DateTime now) =>
      status == SessionStatus.scheduled &&
      !startsAt.isAfter(now) &&
      endsAt.isAfter(now);

  bool get _isWritable => group.isActive;

  /// Time, location, and notes changes for a session that has not been
  /// cancelled or completed.
  bool get canEdit => _isWritable && status == SessionStatus.scheduled;

  bool get canCancel => canEdit;

  bool get canEditNotes => _isWritable && !isCancelled;

  bool canComplete(DateTime now) => canEdit && !startsAt.isAfter(now);

  bool canRestore(DateTime now) =>
      _isWritable && isCancelled && startsAt.isAfter(now);

  /// Whether attendance has not opened yet: it opens on the session's Cairo
  /// calendar day.
  bool isBeforeAttendanceDay(DateTime now) =>
      CairoTime.calendarDaysBetween(now, startsAt) > 0;

  /// Whether a payment amount may be attached to this existing session.
  bool get canAttachPayment =>
      _isWritable && !group.isSuspended && !isCancelled;

  bool canTakeAttendance(DateTime now) =>
      _isWritable && !isCancelled && !isBeforeAttendanceDay(now);

  @override
  bool operator ==(Object other) =>
      other is ClassSession &&
      other.id == id &&
      other.group == group &&
      other.scheduleEntryId == scheduleEntryId &&
      other.startsAt == startsAt &&
      other.endsAt == endsAt &&
      other.location == location &&
      other.status == status &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(
    id,
    group,
    scheduleEntryId,
    startsAt,
    endsAt,
    location,
    status,
    notes,
  );
}
