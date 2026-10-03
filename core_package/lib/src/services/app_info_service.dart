import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  AppInfoService._();

  static final AppInfoService instance = AppInfoService._();

  late final PackageInfo _packageInfo;

  String get appName => _packageInfo.appName;
  String get packageName => _packageInfo.packageName;
  String get version => _packageInfo.version;
  String get buildNumber => _packageInfo.buildNumber;

  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }
}
