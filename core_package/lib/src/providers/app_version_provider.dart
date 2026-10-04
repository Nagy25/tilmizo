import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_info_service.dart';

final appVersionProvider = Provider<String>(
  (ref) => AppInfoService.instance.version,
);
