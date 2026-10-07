import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../generated/locale_keys.g.dart';

/// A localized byte size, such as `4.2 ميجابايت`.
String formatByteSize(int bytes) {
  final size = splitByteSize(bytes);
  return switch (size.unit) {
    ByteUnit.bytes => LocaleKeys.storage_bytes,
    ByteUnit.kilobytes => LocaleKeys.storage_kilobytes,
    ByteUnit.megabytes => LocaleKeys.storage_megabytes,
    ByteUnit.gigabytes => LocaleKeys.storage_gigabytes,
  }.tr(args: [size.value]);
}
