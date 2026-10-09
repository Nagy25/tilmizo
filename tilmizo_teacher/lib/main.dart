import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilmizo_teacher/app/my_app.dart';
import 'package:tilmizo_teacher/generated/codegen_loader.g.dart';

const arabic = Locale('ar');
const webPushVapidKey = String.fromEnvironment('WEB_PUSH_VAPID_KEY');
const teacherWebFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyBMMv2Du2eDbOjRSMhi8hKHqL2M1gMcW-c',
  appId: '1:541147574009:web:341cdca95845b08d4e3c28',
  messagingSenderId: '541147574009',
  projectId: 'telmizo-25dff',
  authDomain: 'telmizo-25dff.firebaseapp.com',
  storageBucket: 'telmizo-25dff.firebasestorage.app',
  measurementId: 'G-53N3QYCPR7',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fails fast when SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY is missing.
  final supabaseConfig = SupabaseConfig.fromEnvironment();
  registerTelmizoFontLicenses();
  // Class times are Africa/Cairo wall-clock times with daylight saving.
  CairoTime.ensureInitialized();
  if (kIsWeb && webPushVapidKey.isEmpty) {
    debugPrint('Web push unavailable: WEB_PUSH_VAPID_KEY is missing.');
  }
  // Web push requires the public VAPID key at build time. A slow or failing
  // Firebase start never delays the UI.
  PushNotificationsBootstrap.start(
    webOptions: kIsWeb ? teacherWebFirebaseOptions : null,
    webVapidKey: webPushVapidKey,
  );

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
      // Screens surface failures explicitly; automatic retries would hide
      // them behind repeated background requests.
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          notificationAppProvider.overrideWithValue(NotificationApp.teacher),
        ],
        retry: (_, _) => null,
        child: const MyApp(),
      ),
    ),
  );
}
