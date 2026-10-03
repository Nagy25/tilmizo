import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilmizo_teacher/app/my_app.dart';
import 'package:tilmizo_teacher/generated/codegen_loader.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    EasyLocalization.ensureInitialized(),
    AppInfoService.instance.init(),
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const CodegenLoader(),
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}
