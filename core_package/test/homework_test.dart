import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row([Map<String, dynamic> overrides = const {}]) => {
  'id': 'h1',
  'group_id': 'g1',
  'session_id': 's1',
  'teacher_id': 't1',
  'instructions': 'حل تمارين صفحة 42',
  'submission_type': 'link',
  'due_date': '2026-10-10',
  'created_at': '2026-10-05T10:00:00+00:00',
  ...overrides,
};

void main() {
  setUpAll(CairoTime.ensureInitialized);

  group('Homework.fromRow', () {
    test('parses a plain row', () {
      final homework = Homework.fromRow(_row());
      expect(homework.id, 'h1');
      expect(homework.groupId, 'g1');
      expect(homework.sessionId, 's1');
      expect(homework.teacherId, 't1');
      expect(homework.instructions, 'حل تمارين صفحة 42');
      expect(homework.submissionType, HomeworkSubmissionType.link);
      expect(homework.dueDate, DateTime.utc(2026, 10, 10));
      expect(homework.createdAt, DateTime.utc(2026, 10, 5, 10));
      expect(homework.session, isNull);
      expect(homework.attachments, isEmpty);
    });

    test('parses embedded session and attachments', () {
      final homework = Homework.fromRow(
        _row({
          'session': {
            'starts_at': '2026-10-05T17:00:00+03:00',
            'status': 'cancelled',
          },
          'attachments': [
            {'homework_id': 'h1', 'group_id': 'g1', 'resource_id': 'r1'},
            {'homework_id': 'h1', 'group_id': 'g1', 'resource_id': 'r2'},
          ],
        }),
      );
      expect(homework.session?.startsAt, DateTime.utc(2026, 10, 5, 14));
      expect(homework.session?.isCancelled, isTrue);
      expect(homework.resourceIds, ['r1', 'r2']);
      expect(
        homework.attachments.first,
        const HomeworkAttachmentRef(
          homeworkId: 'h1',
          groupId: 'g1',
          resourceId: 'r1',
        ),
      );
    });

    test('files-only homework has no instructions or due date', () {
      final homework = Homework.fromRow(
        _row({
          'instructions': null,
          'due_date': null,
          'submission_type': 'none',
        }),
      );
      expect(homework.instructions, isNull);
      expect(homework.dueDate, isNull);
      expect(homework.submissionType, HomeworkSubmissionType.none);
      // A session hidden by RLS embeds as null.
      expect(Homework.fromRow(_row({'session': null})).session, isNull);
    });

    test('rejects missing columns and unknown values', () {
      for (final key in [
        'id',
        'group_id',
        'session_id',
        'teacher_id',
        'submission_type',
        'created_at',
      ]) {
        expect(
          () => Homework.fromRow(_row({key: null})),
          throwsFormatException,
          reason: key,
        );
      }
      expect(
        () => Homework.fromRow(_row({'submission_type': 'upload'})),
        throwsFormatException,
      );
      expect(
        () => Homework.fromRow(_row({'due_date': '2026-10-10T00:00:00Z'})),
        throwsFormatException,
      );
    });

    test('is a value type', () {
      expect(Homework.fromRow(_row()), Homework.fromRow(_row()));
      expect(
        Homework.fromRow(_row()).hashCode,
        Homework.fromRow(_row()).hashCode,
      );
      expect(
        Homework.fromRow(_row()),
        isNot(Homework.fromRow(_row({'due_date': null}))),
      );
    });

    test('list columns embed the session through its composite key', () {
      expect(
        Homework.listColumns,
        contains('session:class_sessions!homework_session_group_fk'),
      );
      expect(Homework.listColumns, contains('attachments:homework_resources('));
    });
  });

  group('Cairo submission cutoff', () {
    final homework = Homework.fromRow(_row());

    test('open through the last Cairo second of the due date', () {
      // 2026-10-10 23:59:59 in Cairo (UTC+3 in October 2026).
      expect(
        homework.acceptsSubmissionAt(DateTime.utc(2026, 10, 10, 20, 59, 59)),
        isTrue,
      );
      // Already the 11th in Cairo while still the 10th in UTC.
      expect(
        homework.acceptsSubmissionAt(DateTime.utc(2026, 10, 10, 21)),
        isFalse,
      );
      // Still the 10th in Cairo early in the UTC morning.
      expect(
        homework.acceptsSubmissionAt(DateTime.utc(2026, 10, 9, 21)),
        isTrue,
      );
    });

    test('without a due date submissions stay open', () {
      final open = Homework.fromRow(_row({'due_date': null}));
      expect(open.acceptsSubmissionAt(DateTime.utc(2030)), isTrue);
    });
  });

  group('HomeworkLinkSubmission', () {
    test('parses and reports replacement', () {
      final row = {
        'homework_id': 'h1',
        'student_id': 'st1',
        'url': 'https://drive.example.com/file',
        'created_at': '2026-10-06T08:00:00Z',
        'updated_at': '2026-10-06T08:00:00Z',
      };
      final first = HomeworkLinkSubmission.fromRow(row);
      expect(first.url, 'https://drive.example.com/file');
      expect(first.wasReplaced, isFalse);
      final replaced = HomeworkLinkSubmission.fromRow({
        ...row,
        'updated_at': '2026-10-07T08:00:00Z',
      });
      expect(replaced.wasReplaced, isTrue);
      expect(first, HomeworkLinkSubmission.fromRow(row));
      expect(
        () => HomeworkLinkSubmission.fromRow({...row, 'url': null}),
        throwsFormatException,
      );
    });

    test('link validation mirrors the backend check', () {
      expect(isValidHomeworkLink('https://a.b/c'), isTrue);
      expect(isValidHomeworkLink('HTTPS://A.B'), isTrue);
      expect(isValidHomeworkLink('http://a.b'), isFalse);
      expect(isValidHomeworkLink('https://'), isFalse);
      expect(isValidHomeworkLink('https://a b'), isFalse);
      expect(isValidHomeworkLink('https://${'a' * 2040}'), isTrue); // 2048
      expect(isValidHomeworkLink('https://${'a' * 2041}'), isFalse);
    });
  });

  group('calendar dates', () {
    test('format without zone conversion and round-trip', () {
      final date = DateTime.utc(2026, 3, 7);
      expect(formatCalendarDate(date), '2026-03-07');
      expect(parseCalendarDate(formatCalendarDate(date)), date);
      // A local late-evening value keeps its calendar fields.
      expect(formatCalendarDate(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
      expect(() => parseCalendarDate('2026-3-7'), throwsFormatException);
    });
  });
}
