import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/auth/domain/student_destination.dart';
import 'package:tilmizo_student/features/auth/presentation/controllers/app_flow_controller.dart';
import 'package:tilmizo_student/features/group_access/domain/student_access_state.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

Future<StudentFlowResult> resolve(TestBackend backend) {
  final container = backend.createContainer();
  container.listen(appStartupProvider, (_, _) {});
  return container.read(appStartupProvider.future);
}

TestBackend signedIn({List entries = const []}) => TestBackend(
  auth: FakePhoneAuthService(signedIn: true),
  access: FakeGroupAccessRepository([...entries.cast()]),
);

void main() {
  setUpAll(initTestPreferences);

  test('no session → phone login', () async {
    expect(
      (await resolve(TestBackend())).destination,
      StudentDestination.phoneLogin,
    );
  });

  test('incomplete student profile → completion (no subject needed)', () async {
    final backend = signedIn();
    backend.profiles.profile = buildProfile(fullName: '  ');
    expect(
      (await resolve(backend)).destination,
      StudentDestination.completeProfile,
    );

    backend.profiles.profile = buildProfile();
    expect(
      (await resolve(backend)).destination,
      StudentDestination.emptyGroups,
    );
  });

  test('a single group needing attention opens its status screen', () async {
    final result = await resolve(signedIn(entries: [buildEntry()]));
    expect(result.destination, StudentDestination.groupsHome);
    expect(result.focus?.state, StudentAccessState.pendingJoin);
  });

  test('approved or several groups open the groups home', () async {
    final approved = await resolve(signedIn(entries: [approvedEntry()]));
    expect(approved.destination, StudentDestination.groupsHome);
    expect(approved.focus, isNull);

    final several = await resolve(
      signedIn(
        entries: [
          buildEntry(),
          buildEntry(groupId: 'g2'),
        ],
      ),
    );
    expect(several.focus, isNull);
  });

  test('offline startup surfaces a retryable failure', () async {
    final backend = signedIn();
    backend.access.overviewFailure = const AppFailure(AppFailureType.network);
    await expectLater(resolve(backend), throwsA(isA<AppFailure>()));
  });

  test('expired session signs out and returns to login', () async {
    final backend = signedIn();
    backend.profiles.fetchFailure = const AppFailure(
      AppFailureType.sessionExpired,
    );
    expect((await resolve(backend)).destination, StudentDestination.phoneLogin);
    expect(backend.auth.signOutCount, 1);
  });
}
