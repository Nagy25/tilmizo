import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilmizo_teacher/app/my_app.dart';
import 'package:tilmizo_teacher/features/announcements/data/announcements_repository_impl.dart';
import 'package:tilmizo_teacher/features/attendance/data/attendance_repository_impl.dart';
import 'package:tilmizo_teacher/features/classes/data/classes_repository_impl.dart';
import 'package:tilmizo_teacher/features/group_access/data/group_access_repository_impl.dart';
import 'package:tilmizo_teacher/features/groups/data/groups_repository_impl.dart';
import 'package:tilmizo_teacher/features/homework/data/homework_repository_impl.dart';
import 'package:tilmizo_teacher/features/payments/data/payments_repository_impl.dart';
import 'package:tilmizo_teacher/features/profile/data/resource_storage_usage_repository_impl.dart';
import 'package:tilmizo_teacher/features/profile/data/supabase_profile_repository.dart';
import 'package:tilmizo_teacher/features/resources/data/resource_file_picker.dart';
import 'package:tilmizo_teacher/features/resources/data/resources_repository_impl.dart';
import 'package:tilmizo_teacher/features/teacher_students/data/teacher_students_repository_impl.dart';
import 'package:tilmizo_teacher/generated/codegen_loader.g.dart';
import 'package:tilmizo_teacher/router/app_router.dart';

import 'fake_announcements.dart';
import 'fake_classes.dart';
import 'fake_group_access.dart';
import 'fake_homework.dart';
import 'fake_payments.dart';
import 'fake_resources.dart';
import 'fake_teacher_students.dart';
import 'fakes.dart';

const arabic = Locale('ar');

/// Fake-backed dependencies for one test.
class TestBackend {
  TestBackend({
    FakePhoneAuthService? auth,
    FakeProfileRepository? profiles,
    FakeGroupsRepository? groups,
    FakeGroupAccessRepository? access,
    FakeTeacherStudentsRepository? teacherStudents,
    FakeClassesRepository? classes,
    FakeAttendanceRepository? attendance,
    FakeResourcesRepository? resources,
    FakePaymentsRepository? payments,
    FakeAnnouncementsRepository? announcements,
    FakeHomeworkRepository? homework,
    this.now,
  }) : homework = homework ?? FakeHomeworkRepository(),
       announcements = announcements ?? FakeAnnouncementsRepository(),
       payments = payments ?? FakePaymentsRepository(),
       resources = resources ?? FakeResourcesRepository(),
       classes = classes ?? FakeClassesRepository(),
       attendance = attendance ?? FakeAttendanceRepository(),
       access = access ?? FakeGroupAccessRepository(),
       teacherStudents = teacherStudents ?? FakeTeacherStudentsRepository(),
       auth = auth ?? FakePhoneAuthService(),
       profiles = profiles ?? FakeProfileRepository(),
       groups = groups ?? FakeGroupsRepository();

  final FakePhoneAuthService auth;
  final FakeProfileRepository profiles;
  final FakeGroupsRepository groups;
  final FakeGroupAccessRepository access;
  final FakeTeacherStudentsRepository teacherStudents;
  final FakeClassesRepository classes;
  final FakeAttendanceRepository attendance;
  final FakeResourcesRepository resources;
  final FakePaymentsRepository payments;
  final FakeAnnouncementsRepository announcements;
  final FakeHomeworkRepository homework;
  final usage = FakeUsageRepository();
  final uploader = FakeContentUploader();
  final filePicker = FakeFilePicker();
  final files = FakeResourceFileService();

  /// A fixed clock for screens that compare against the current time.
  final DateTime? now;

  List<Override> get overrides => [
    phoneAuthServiceProvider.overrideWithValue(auth),
    profileRepositoryProvider.overrideWithValue(profiles),
    groupsRepositoryProvider.overrideWithValue(groups),
    groupAccessRepositoryProvider.overrideWithValue(access),
    teacherStudentsRepositoryProvider.overrideWithValue(teacherStudents),
    classesRepositoryProvider.overrideWithValue(classes),
    attendanceRepositoryProvider.overrideWithValue(attendance),
    resourcesRepositoryProvider.overrideWithValue(resources),
    paymentsRepositoryProvider.overrideWithValue(payments),
    announcementsRepositoryProvider.overrideWithValue(announcements),
    homeworkRepositoryProvider.overrideWithValue(homework),
    resourceStorageUsageRepositoryProvider.overrideWithValue(usage),
    resourceContentUploaderProvider.overrideWithValue(uploader),
    resourceFilePickerProvider.overrideWithValue(filePicker),
    resourceFileServiceProvider.overrideWithValue(files),
    if (now case final now?) clockProvider.overrideWithValue(() => now),
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
  CairoTime.ensureInitialized();
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

/// Pushes [route] on the running app's router and settles.
Future<void> openRoute(WidgetTester tester, PageRouteInfo route) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MyApp)),
  );
  unawaited(container.read(appRouterProvider).push(route));
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view in the first scrollable and taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  // Built is not the same as on screen: bring it fully into view.
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// A tall phone viewport so long lazy lists build every item.
void useTallPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 4000)
    ..devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}
