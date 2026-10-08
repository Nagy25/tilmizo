import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row([Map<String, dynamic> overrides = const {}]) => {
  'id': 'a1',
  'group_id': 'g1',
  'teacher_id': 't1',
  'title': 'موعد الاختبار',
  'body': 'الاختبار يوم الخميس.\nراجعوا الفصل الثالث.',
  'created_at': '2026-10-05T10:00:00.123456+00:00',
  'updated_at': '2026-10-05T10:00:00.123456+00:00',
  ...overrides,
};

void main() {
  test('parses an announcement row', () {
    final announcement = Announcement.fromRow(_row());

    expect(announcement.id, 'a1');
    expect(announcement.groupId, 'g1');
    expect(announcement.teacherId, 't1');
    expect(announcement.title, 'موعد الاختبار');
    expect(announcement.body, contains('\n'));
    expect(announcement.createdAt.isUtc, isTrue);
    expect(
      announcement.createdAt,
      DateTime.utc(2026, 10, 5, 10, 0, 0, 123, 456),
    );
    expect(announcement.isEdited, isFalse);
  });

  test('converts offset timestamps to UTC', () {
    final announcement = Announcement.fromRow(
      _row({
        'created_at': '2026-10-05T13:00:00+03:00',
        'updated_at': '2026-10-05T13:00:00+03:00',
      }),
    );
    expect(announcement.createdAt, DateTime.utc(2026, 10, 5, 10));
  });

  test('a later updated_at marks the announcement as edited', () {
    final announcement = Announcement.fromRow(
      _row({'updated_at': '2026-10-06T08:00:00Z'}),
    );
    expect(announcement.isEdited, isTrue);
  });

  test('ignores extra columns such as embedded reads', () {
    final announcement = Announcement.fromRow(
      _row({
        'reads': [
          {'student_id': 's1', 'read_at': '2026-10-05T11:00:00Z'},
        ],
      }),
    );
    expect(announcement.id, 'a1');
  });

  test('rejects missing or blank required columns', () {
    for (final key in [
      'id',
      'group_id',
      'teacher_id',
      'title',
      'body',
      'created_at',
      'updated_at',
    ]) {
      expect(
        () => Announcement.fromRow(_row({key: null})),
        throwsFormatException,
        reason: key,
      );
      expect(
        () => Announcement.fromRow(_row({key: ''})),
        throwsFormatException,
        reason: key,
      );
    }
  });

  test('rejects malformed timestamps', () {
    expect(
      () => Announcement.fromRow(_row({'created_at': 'yesterday'})),
      throwsFormatException,
    );
  });

  test('is a value type', () {
    expect(Announcement.fromRow(_row()), Announcement.fromRow(_row()));
    expect(
      Announcement.fromRow(_row()).hashCode,
      Announcement.fromRow(_row()).hashCode,
    );
    expect(
      Announcement.fromRow(_row()),
      isNot(Announcement.fromRow(_row({'title': 'آخر'}))),
    );
  });

  test('exposes backend limits and the select list', () {
    expect(Announcement.titleMaxLength, 200);
    expect(Announcement.bodyMaxLength, 10000);
    expect(
      Announcement.columns,
      'id, group_id, teacher_id, title, body, created_at, updated_at',
    );
  });
}
