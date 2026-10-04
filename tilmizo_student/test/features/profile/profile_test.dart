import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilmizo_student/features/profile/data/profile_remote_data_source.dart';
import 'package:tilmizo_student/features/profile/data/profile_repository_impl.dart';
import 'package:tilmizo_student/features/profile/domain/student_profile.dart';
import 'package:tilmizo_student/features/profile/presentation/controllers/profile_form_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

final class _FakeDataSource implements ProfileRemoteDataSource {
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async => {
    'id': userId,
    'full_name': null,
    'phone': testPhone,
    'avatar_url': null,
  };

  @override
  Future<Map<String, dynamic>?> updateProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    lastPayload = payload;
    return {
      'id': userId,
      'full_name': payload['full_name'],
      'phone': testPhone,
      'avatar_url': null,
    };
  }
}

void main() {
  setUpAll(initTestPreferences);

  test('student completeness needs only a name and verified phone', () {
    expect(buildProfile().isComplete, isTrue);
    expect(buildProfile(fullName: null).isComplete, isFalse);
    expect(
      const StudentProfile(id: 'x', fullName: 'عمر', phone: '').isComplete,
      isFalse,
    );
  });

  test('update sends only the trimmed full name', () async {
    final dataSource = _FakeDataSource();
    final repository = ProfileRepositoryImpl(
      dataSource,
      FakePhoneAuthService(signedIn: true),
    );
    final saved = await repository.updateFullName('  عمر خالد ');
    expect(dataSource.lastPayload, {'full_name': 'عمر خالد'});
    expect(saved.isComplete, isTrue);
    await expectLater(
      repository.updateFullName(' '),
      throwsA(isA<AppFailure>()),
    );
  });

  test('form controller ignores blank names', () async {
    final backend = TestBackend(auth: FakePhoneAuthService(signedIn: true));
    final container = backend.createContainer();
    container.listen(profileFormControllerProvider, (_, _) {});
    expect(
      await container.read(profileFormControllerProvider.notifier).submit(' '),
      isNull,
    );
    expect(backend.profiles.updates, isEmpty);
  });
}
