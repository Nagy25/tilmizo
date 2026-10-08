import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../generated/locale_keys.g.dart';

extension AnnouncementFormatting on BuildContext {
  String get _locale => locale.toLanguageTag();

  /// `نُشر 5 أكتوبر 2026 1:00 م`, in Cairo time.
  String announcementPublished(Announcement announcement) {
    final cairo = CairoTime.toCairo(announcement.createdAt);
    return LocaleKeys.announcements_published_on.tr(
      args: [
        '${DateFormat.yMMMd(_locale).format(cairo)} '
            '${DateFormat.jm(_locale).format(cairo)}',
      ],
    );
  }
}
