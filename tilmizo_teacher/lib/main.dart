import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilmizo_teacher/app/my_app.dart';
import 'package:tilmizo_teacher/generated/codegen_loader.g.dart';

const arabic = Locale('ar');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fails fast when SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY is missing.
  final supabaseConfig = SupabaseConfig.fromEnvironment();
  registerTelmizoFontLicenses();

  await Future.wait([
    EasyLocalization.ensureInitialized(),
    AppInfoService.instance.init(),
    initializeSupabase(supabaseConfig),
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [arabic],
      path: 'assets/translations',
      assetLoader: const CodegenLoader(),
      startLocale: arabic,
      fallbackLocale: arabic,
      saveLocale: false,
      // Arabic needs its full plural categories (few, many).
      ignorePluralRules: false,
      // Screens surface failures explicitly; automatic retries would hide
      // them behind repeated background requests.
      child: ProviderScope(retry: (_, _) => null, child: const MyApp()),
    ),
  );
}
