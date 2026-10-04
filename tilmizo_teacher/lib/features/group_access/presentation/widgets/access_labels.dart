import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

String studentDisplayName(String? name) {
  final trimmed = name?.trim();
  return trimmed == null || trimmed.isEmpty
      ? LocaleKeys.access_unnamed_student.tr()
      : trimmed;
}

String platformLabel(DevicePlatform platform) => switch (platform) {
  DevicePlatform.android => LocaleKeys.access_platform_android,
  DevicePlatform.ios => LocaleKeys.access_platform_ios,
}.tr();

IconData platformIcon(DevicePlatform platform) => switch (platform) {
  DevicePlatform.android => Icons.phone_android,
  DevicePlatform.ios => Icons.phone_iphone,
};

String accessDate(BuildContext context, DateTime value) =>
    DateFormat.yMMMd(context.locale.toLanguageTag()).format(value.toLocal());
