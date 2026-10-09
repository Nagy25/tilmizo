import 'package:flutter/foundation.dart';

/// What a notification is about. Values mirror the `event_type` check
/// constraint of `public.user_notifications`; anything else parses as
/// [unknown] so a newer backend event never breaks older clients.
enum NotificationEventType {
  announcementNew('announcement_new', NotificationTargetKind.announcement),
  homeworkNew('homework_new', NotificationTargetKind.homework),
  homeworkDueSoon('homework_due_soon', NotificationTargetKind.homework),
  resourceNew('resource_new', NotificationTargetKind.resource),
  sessionRescheduled('session_rescheduled', NotificationTargetKind.session),
  sessionCancelled('session_cancelled', NotificationTargetKind.session),
  sessionUpcoming('session_upcoming', NotificationTargetKind.session),
  paymentChargeNew('payment_charge_new', NotificationTargetKind.payment),
  paymentRecorded('payment_recorded', NotificationTargetKind.payment),
  paymentOverdue('payment_overdue', NotificationTargetKind.payment),
  unknown('unknown', NotificationTargetKind.none);

  const NotificationEventType(this.value, this.targetKind);

  final String value;

  /// The table `target_id` refers to.
  final NotificationTargetKind targetKind;

  static NotificationEventType parse(Object? value) {
    for (final type in values) {
      if (type != unknown && type.value == value) return type;
    }
    return unknown;
  }
}

/// The record a notification's `target_id` points at: a homework, an
/// announcement, a resource, a class session, or a payment obligation.
enum NotificationTargetKind {
  homework,
  announcement,
  resource,
  session,
  payment,
  none,
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Where a notification wants to take the user. It is only a navigation
/// hint: the destination must be re-read under the normal access rules.
@immutable
final class NotificationTarget {
  const NotificationTarget({
    required this.eventType,
    this.targetId,
    this.groupId,
  });

  /// Reads the FCM `data` payload (`event_type`, `target_id`). A malformed
  /// target ID is dropped rather than passed to a query.
  factory NotificationTarget.fromPushData(Map<String, dynamic> data) =>
      NotificationTarget(
        eventType: NotificationEventType.parse(data['event_type']),
        targetId: _uuidOrNull(data['target_id']),
      );

  final NotificationEventType eventType;
  final String? targetId;

  /// Known only for rows from the notification center, not for pushes.
  final String? groupId;

  @override
  bool operator ==(Object other) =>
      other is NotificationTarget &&
      other.eventType == eventType &&
      other.targetId == targetId &&
      other.groupId == groupId;

  @override
  int get hashCode => Object.hash(eventType, targetId, groupId);
}

String? _uuidOrNull(Object? value) =>
    value is String && _uuidPattern.hasMatch(value) ? value : null;

/// One row of `public.user_notifications`, readable only by its recipient.
@immutable
final class AppNotification {
  const AppNotification({
    required this.id,
    required this.eventType,
    required this.title,
    required this.createdAt,
    this.groupId,
    this.targetId,
    this.body,
    this.readAt,
  });

  /// Parses a row selected with [columns]. Throws [FormatException] when a
  /// required column is missing or malformed.
  factory AppNotification.fromRow(Map<String, dynamic> row) {
    final body = row['body'];
    final readAt = row['read_at'];
    return AppNotification(
      id: _required(row, 'id'),
      groupId: _optional(row, 'group_id'),
      eventType: NotificationEventType.parse(row['event_type']),
      targetId: _optional(row, 'target_id'),
      title: _required(row, 'title'),
      body: body is String && body.trim().isNotEmpty ? body : null,
      createdAt: DateTime.parse(_required(row, 'created_at')).toUtc(),
      readAt: readAt is String ? DateTime.parse(readAt).toUtc() : null,
    );
  }

  /// The column list for `from('user_notifications').select(...)`.
  static const columns =
      'id, group_id, event_type, target_id, title, body, created_at, read_at';

  final String id;
  final String? groupId;
  final NotificationEventType eventType;
  final String? targetId;
  final String title;
  final String? body;
  final DateTime createdAt;

  /// Null while unread.
  final DateTime? readAt;

  bool get isRead => readAt != null;

  NotificationTarget get target => NotificationTarget(
    eventType: eventType,
    targetId: targetId,
    groupId: groupId,
  );

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    groupId: groupId,
    eventType: eventType,
    targetId: targetId,
    title: title,
    body: body,
    createdAt: createdAt,
    readAt: readAt ?? at,
  );

  @override
  bool operator ==(Object other) =>
      other is AppNotification &&
      other.id == id &&
      other.groupId == groupId &&
      other.eventType == eventType &&
      other.targetId == targetId &&
      other.title == title &&
      other.body == body &&
      other.createdAt == createdAt &&
      other.readAt == readAt;

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    eventType,
    targetId,
    title,
    body,
    createdAt,
    readAt,
  );

  static String _required(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing notification column', key);
  }

  static String? _optional(Map<String, dynamic> row, String key) {
    final value = row[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
