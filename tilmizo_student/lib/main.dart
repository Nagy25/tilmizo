import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilmizo_student/app/my_app.dart';
import 'package:tilmizo_student/generated/codegen_loader.g.dart';

const arabic = Locale('ar');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fails fast when SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY is missing.
  final supabaseConfig = SupabaseConfig.fromEnvironment();
  registerTelmizoFontLicenses();
  CairoTime.ensureInitialized();

  final (sharedPreferences, _, _, _) = await (
    SharedPreferences.getInstance(),
    EasyLocalization.ensureInitialized(),
    AppInfoService.instance.init(),
    initializeSupabase(supabaseConfig),
  ).wait;

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
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        // Screens surface failures explicitly; automatic retries would hide
        // them behind repeated background requests.
        retry: (_, _) => null,
        child: const MyApp(),
      ),
    ),
  );
}
