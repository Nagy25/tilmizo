import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilmizo_student/app/my_app.dart';
import 'package:tilmizo_student/features/group_access/data/group_access_repository_impl.dart';
import 'package:tilmizo_student/features/profile/data/profile_repository_impl.dart';
import 'package:tilmizo_student/generated/codegen_loader.g.dart';
import 'package:tilmizo_student/features/student_classes/data/student_classes_repository_impl.dart';

import 'fakes.dart';

const arabic = Locale('ar');

class TestBackend {
  TestBackend({
    this.preferences,
    FakePhoneAuthService? auth,
    FakeProfileRepository? profiles,
    FakeGroupAccessRepository? access,
    FakeStudentClassesRepository? classes,
  }) : auth = auth ?? FakePhoneAuthService(),
       profiles = profiles ?? FakeProfileRepository(),
       access = access ?? FakeGroupAccessRepository(),
       classes = classes ?? FakeStudentClassesRepository();

  final FakePhoneAuthService auth;
  final FakeProfileRepository profiles;
  final FakeGroupAccessRepository access;
  final FakeStudentClassesRepository classes;

  /// Defaults to [testPreferences].
  final SharedPreferences? preferences;

  List<Override> get overrides => [
    phoneAuthServiceProvider.overrideWithValue(auth),
    profileRepositoryProvider.overrideWithValue(profiles),
    groupAccessRepositoryProvider.overrideWithValue(access),
    studentClassesRepositoryProvider.overrideWithValue(classes),
    deviceInfoServiceProvider.overrideWithValue(FakeDeviceInfoService()),
    appVersionProvider.overrideWithValue('1.0.0'),
    sharedPreferencesProvider.overrideWithValue(preferences ?? testPreferences),
  ];

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: overrides,
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    return container;
  }
}

/// Mock preferences shared by tests; set up by [initTestPreferences].
late SharedPreferences testPreferences;

Future<void> initTestPreferences() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  CairoTime.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  testPreferences = await SharedPreferences.getInstance();
}

Future<void> initTestLocalization() async {
  await initTestPreferences();
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
}

/// Pumps the full application on a tall phone-sized view so screens rarely
/// need scrolling in tests.
Future<void> pumpStudentApp(
  WidgetTester tester,
  TestBackend backend, {
  Size viewSize = const Size(480, 1600),
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [arabic],
      path: 'assets/translations',
      assetLoader: const CodegenLoader(),
      startLocale: arabic,
      fallbackLocale: arabic,
      saveLocale: false,
      ignorePluralRules: false,
      child: ProviderScope(
        overrides: backend.overrides,
        retry: (_, _) => null,
        child: const MyApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
