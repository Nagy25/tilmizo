import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../generated/locale_keys.g.dart';

extension AnnouncementFormatting on BuildContext {
  String get _locale => locale.toLanguageTag();

  /// Cairo date and time of [instant], such as `5 أكتوبر 2026 1:00 م`.
  String announcementDate(DateTime instant) {
    final cairo = CairoTime.toCairo(instant);
    return '${DateFormat.yMMMd(_locale).format(cairo)} '
        '${DateFormat.jm(_locale).format(cairo)}';
  }
}

/// User-safe message for a failed announcement read or write.
String announcementFailureMessage(Object error) =>
    switch (failureTypeOf(error)) {
      AppFailureType.notEligible =>
        LocaleKeys.announcement_error_group_not_writable.tr(),
      AppFailureType.notFound => LocaleKeys.announcement_error_not_found.tr(),
      AppFailureType.invalidInput ||
      AppFailureType.rejected => LocaleKeys.announcement_error_invalid.tr(),
      final type => appFailureMessage(type),
    };
