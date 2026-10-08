import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../generated/locale_keys.g.dart';
import '../domain/homework_repository.dart';

extension HomeworkTypeLabels on HomeworkSubmissionType {
  String get label => switch (this) {
    HomeworkSubmissionType.manual => LocaleKeys.homework_type_manual,
    HomeworkSubmissionType.link => LocaleKeys.homework_type_link,
    HomeworkSubmissionType.none => LocaleKeys.homework_type_none,
  }.tr();

  String get body => switch (this) {
    HomeworkSubmissionType.manual => LocaleKeys.homework_type_manual_body,
    HomeworkSubmissionType.link => LocaleKeys.homework_type_link_body,
    HomeworkSubmissionType.none => LocaleKeys.homework_type_none_body,
  }.tr();

  IconData get icon => switch (this) {
    HomeworkSubmissionType.manual => Icons.back_hand_outlined,
    HomeworkSubmissionType.link => Icons.link,
    HomeworkSubmissionType.none => Icons.menu_book_outlined,
  };
}

extension HomeworkFormatting on BuildContext {
  String get _locale => locale.toLanguageTag();

  /// A heading derived from the session date; homework has no title.
  String homeworkHeading(Homework homework) => switch (homework.session) {
    final session? => LocaleKeys.homework_heading.tr(
      args: [
        DateFormat.MMMEd(_locale).format(CairoTime.toCairo(session.startsAt)),
      ],
    ),
    null => LocaleKeys.homework_heading_fallback.tr(),
  };

  /// The first instruction line, or the attachment count for files-only
  /// homework.
  String homeworkPreview(Homework homework) =>
      homework.instructions?.trim().split('\n').first ??
      LocaleKeys.homework_files_only.tr();

  /// A Cairo calendar date, formatted without time-zone conversion.
  String calendarDate(DateTime date) => DateFormat.yMMMEd(_locale).format(date);

  String homeworkDue(Homework homework) => switch (homework.dueDate) {
    final due? => LocaleKeys.homework_due_on.tr(args: [calendarDate(due)]),
    null => LocaleKeys.homework_no_due.tr(),
  };

  String homeworkInstant(DateTime instant) {
    final cairo = CairoTime.toCairo(instant);
    return '${DateFormat.yMMMd(_locale).format(cairo)} '
        '${DateFormat.jm(_locale).format(cairo)}';
  }
}

/// User-safe message for a failed homework read or write.
String homeworkFailureMessage(Object? error) => switch (error) {
  HomeworkFailure(:final reason) => switch (reason) {
    HomeworkFailureReason.groupNotWritable =>
      LocaleKeys.homework_error_group_not_writable,
    HomeworkFailureReason.sessionCancelled =>
      LocaleKeys.homework_error_session_cancelled,
    HomeworkFailureReason.invalidContent =>
      LocaleKeys.homework_error_invalid_content,
    HomeworkFailureReason.notFound => LocaleKeys.homework_error_not_found,
  }.tr(),
  _ => appFailureMessage(failureTypeOf(error)),
};
