import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_teacher/core/errors/app_failure.dart';
import 'package:tilmizo_teacher/features/profile/domain/profile_update.dart';
import 'package:tilmizo_teacher/features/profile/presentation/controllers/current_profile_controller.dart';
import 'package:tilmizo_teacher/features/profile/presentation/controllers/profile_form_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestBackend backend;

  setUp(() {
    backend = TestBackend(
      auth: FakePhoneAuthService(signedIn: true),
      profiles: FakeProfileRepository(
        buildProfile(fullName: null, teachingSubject: null),
      ),
    );
  });

  test('blank required fields are not submitted', () async {
    final container = backend.createContainer();
    container.listen(profileFormControllerProvider, (_, _) {});
    final controller = container.read(profileFormControllerProvider.notifier);

    expect(
      await controller.submit(fullName: '  ', teachingSubject: 'الرياضيات'),
      isNull,
    );
    expect(
      await controller.submit(fullName: 'أحمد', teachingSubject: ' '),
      isNull,
    );
    expect(backend.profiles.updates, isEmpty);
  });

  test('saves trimmed values and completes the shared profile', () async {
    final container = backend.createContainer();
    container.listen(profileFormControllerProvider, (_, _) {});
    expect(
      (await container.read(currentProfileProvider.future)).isComplete,
      isFalse,
    );

    final saved = await container
        .read(profileFormControllerProvider.notifier)
        .submit(fullName: ' أحمد منصور ', teachingSubject: ' الرياضيات ');

    expect(
      backend.profiles.updates.single,
      ProfileUpdate.tryCreate(
        fullName: 'أحمد منصور',
        teachingSubject: 'الرياضيات',
      ),
    );
    expect(saved?.isComplete, isTrue);
    expect(container.read(currentProfileProvider).value?.isComplete, isTrue);
  });

  test('exposes saving and rejection states', () async {
    final container = backend.createContainer();
    container.listen(profileFormControllerProvider, (_, _) {});
    final controller = container.read(profileFormControllerProvider.notifier);
    backend.profiles.pendingUpdate = Completer();
    backend.profiles.updateFailure = const AppFailure(AppFailureType.rejected);

    final future = controller.submit(fullName: 'أ', teachingSubject: 'ب');
    expect(container.read(profileFormControllerProvider).isSaving, isTrue);

    backend.profiles.pendingUpdate!.complete();
    expect(await future, isNull);
    final state = container.read(profileFormControllerProvider);
    expect(state.isSaving, isFalse);
    expect(state.failure, AppFailureType.rejected);
  });
}
