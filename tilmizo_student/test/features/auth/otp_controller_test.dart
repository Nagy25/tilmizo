import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/auth/presentation/controllers/otp_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(initTestPreferences);

  test('successful verification leaves destination work to splash', () async {
    final backend = TestBackend();
    backend.profiles.fetchFailure = const AppFailure(AppFailureType.network);
    final container = backend.createContainer();
    final provider = otpControllerProvider(testPhone);
    container.listen(provider, (_, _) {});

    final result = await container.read(provider.notifier).verify('123456');

    expect(result, isNotNull);
    expect(result!.destination, isNull);
    expect(container.read(provider).isVerifying, isFalse);
    expect(backend.auth.isAuthenticated, isTrue);
    expect(backend.access.overviewFetches, 0);
  });
}
