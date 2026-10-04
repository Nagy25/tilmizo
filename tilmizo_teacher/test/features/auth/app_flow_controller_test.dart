import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/features/auth/domain/app_destination.dart';
import 'package:tilmizo_teacher/features/auth/presentation/controllers/app_flow_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

Future<AppDestination> resolve(TestBackend backend) {
  final container = backend.createContainer();
  container.listen(appStartupProvider, (_, _) {});
  return container.read(appStartupProvider.future);
}

void main() {
  test('no session routes to login without fetching data', () async {
    final backend = TestBackend();
    expect(await resolve(backend), AppDestination.phoneLogin);
    expect(backend.profiles.fetchCount, 0);
  });

  test('authenticated incomplete profile routes to completion', () async {
    for (final profile in [
      buildProfile(fullName: null),
      buildProfile(fullName: '   '),
      buildProfile(teachingSubject: null),
      buildProfile(teachingSubject: ''),
    ]) {
      final backend = TestBackend(
        auth: FakePhoneAuthService(signedIn: true),
        profiles: FakeProfileRepository(profile),
      );
      expect(await resolve(backend), AppDestination.completeProfile);
    }
  });

  test('complete profile with no groups routes to empty groups', () async {
    final backend = TestBackend(auth: FakePhoneAuthService(signedIn: true));
    expect(await resolve(backend), AppDestination.emptyGroups);
  });

  test('complete profile with groups routes to the dashboard', () async {
    final backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      groups: FakeGroupsRepository([buildGroup()]),
    );
    expect(await resolve(backend), AppDestination.groupsDashboard);
  });

  test('offline startup surfaces a recoverable failure', () async {
    final backend = TestBackend(auth: FakePhoneAuthService(signedIn: true));
    backend.profiles.fetchFailure = const AppFailure(AppFailureType.network);
    await expectLater(
      resolve(backend),
      throwsA(
        isA<AppFailure>().having((f) => f.type, 'type', AppFailureType.network),
      ),
    );
  });

  test('an expired session signs out and routes to login', () async {
    final backend = TestBackend(auth: FakePhoneAuthService(signedIn: true));
    backend.profiles.fetchFailure = const AppFailure(
      AppFailureType.sessionExpired,
    );
    expect(await resolve(backend), AppDestination.phoneLogin);
    expect(backend.auth.signOutCount, 1);
    expect(backend.auth.isAuthenticated, isFalse);
  });

  test('a missing profile row is retryable rather than fatal', () async {
    final backend = TestBackend(auth: FakePhoneAuthService(signedIn: true));
    backend.profiles.fetchFailure = const AppFailure(AppFailureType.notFound);
    final container = backend.createContainer();
    container.listen(appStartupProvider, (_, _) {});
    await expectLater(
      container.read(appStartupProvider.future),
      throwsA(isA<AppFailure>()),
    );

    backend.profiles.fetchFailure = null;
    container.read(resetSessionDataProvider)();
    container.invalidate(appStartupProvider);
    expect(
      await container.read(appStartupProvider.future),
      AppDestination.emptyGroups,
    );
  });

  test('auth failures never surface as raw exceptions', () {
    expect(
      const AuthFailure(AuthFailureType.deliveryFailure).toString(),
      'AuthFailure(deliveryFailure)',
    );
  });
}
