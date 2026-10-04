import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilmizo_teacher/app/my_app.dart';
import 'package:tilmizo_teacher/features/group_access/data/group_access_repository_impl.dart';
import 'package:tilmizo_teacher/features/groups/data/groups_repository_impl.dart';
import 'package:tilmizo_teacher/features/profile/data/supabase_profile_repository.dart';
import 'package:tilmizo_teacher/generated/codegen_loader.g.dart';

import 'fake_group_access.dart';
import 'fakes.dart';

const arabic = Locale('ar');

/// Fake-backed dependencies for one test.
class TestBackend {
  TestBackend({
    FakePhoneAuthService? auth,
    FakeProfileRepository? profiles,
    FakeGroupsRepository? groups,
    FakeGroupAccessRepository? access,
  }) : access = access ?? FakeGroupAccessRepository(),
       auth = auth ?? FakePhoneAuthService(),
       profiles = profiles ?? FakeProfileRepository(),
       groups = groups ?? FakeGroupsRepository();

  final FakePhoneAuthService auth;
  final FakeProfileRepository profiles;
  final FakeGroupsRepository groups;
  final FakeGroupAccessRepository access;

  List<Override> get overrides => [
    phoneAuthServiceProvider.overrideWithValue(auth),
    profileRepositoryProvider.overrideWithValue(profiles),
    groupsRepositoryProvider.overrideWithValue(groups),
    groupAccessRepositoryProvider.overrideWithValue(access),
    appVersionProvider.overrideWithValue('1.0.0'),
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

Future<void> initTestLocalization() async {
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
}

Widget _localized(Widget child) => EasyLocalization(
  supportedLocales: const [arabic],
  path: 'assets/translations',
  assetLoader: const CodegenLoader(),
  startLocale: arabic,
  fallbackLocale: arabic,
  saveLocale: false,
  ignorePluralRules: false,
  child: child,
);

/// Pumps the full application, starting at the splash route.
Future<void> pumpTeacherApp(WidgetTester tester, TestBackend backend) async {
  await tester.pumpWidget(
    _localized(
      ProviderScope(
        overrides: backend.overrides,
        retry: (_, _) => null,
        child: const MyApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps a single widget inside the localized, themed shell.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    _localized(
      ProviderScope(
        overrides: overrides,
        retry: (_, _) => null,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: TelmizoTheme.light(),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
