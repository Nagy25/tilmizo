import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appVersionProvider = Provider<String>(
  (ref) => AppInfoService.instance.version,
);
