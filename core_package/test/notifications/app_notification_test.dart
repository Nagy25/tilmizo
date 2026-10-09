import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/notification_fakes.dart';

void main() {
  test('parses a user_notifications row', () {
    final notification = AppNotification.fromRow({
      'id': 'n1',
      'group_id': 'g1',
      'event_type': 'homework_due_soon',
      'target_id': uuidA,
      'title': 'اقترب موعد تسليم الواجب',
      'body': null,
      'created_at': '2026-10-01T09:00:00.123456+00:00',
      'read_at': null,
    });

    expect(notification.eventType, NotificationEventType.homeworkDueSoon);
    expect(notification.eventType.targetKind, NotificationTargetKind.homework);
    expect(notification.isRead, isFalse);
    expect(notification.body, isNull);
    expect(notification.target.groupId, 'g1');
  });

  test('a read row and an unknown event type stay parseable', () {
    final notification = AppNotification.fromRow({
      'id': 'n1',
      'event_type': 'something_new',
      'title': 'x',
      'body': '  ',
      'created_at': '2026-10-01T09:00:00Z',
      'read_at': '2026-10-01T10:00:00Z',
    });

    expect(notification.eventType, NotificationEventType.unknown);
    expect(notification.eventType.targetKind, NotificationTargetKind.none);
    expect(notification.isRead, isTrue);
    expect(notification.body, isNull);
    expect(notification.groupId, isNull);
  });

  test('a row without a title is rejected', () {
    expect(
      () => AppNotification.fromRow({
        'id': 'n1',
        'event_type': 'homework_new',
        'created_at': '2026-10-01T09:00:00Z',
      }),
      throwsFormatException,
    );
  });

  test('push data is a hint: malformed target IDs are dropped', () {
    expect(
      NotificationTarget.fromPushData({
        'event_type': 'announcement_new',
        'target_id': uuidB,
      }),
      const NotificationTarget(
        eventType: NotificationEventType.announcementNew,
        targetId: uuidB,
      ),
    );
    final injected = NotificationTarget.fromPushData({
      'event_type': 'homework_new',
      'target_id': "1' or 1=1",
    });
    expect(injected.targetId, isNull);
    expect(
      NotificationTarget.fromPushData({}).eventType,
      NotificationEventType.unknown,
    );
  });

  test('markedRead keeps an existing read time', () {
    final first = DateTime.utc(2026, 10, 1);
    final read = buildNotification(readAt: first);
    expect(read.markedRead(DateTime.utc(2026, 10, 5)).readAt, first);
    expect(buildNotification().markedRead(first).readAt, first);
  });
}
