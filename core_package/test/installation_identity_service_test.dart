import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(InstallationIdentityService, SharedPreferences)> create([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    final preferences = await SharedPreferences.getInstance();
    return (
      InstallationIdentityService(SharedPreferencesStoreService(preferences)),
      preferences,
    );
  }

  test('creates a random UUID v4 on first use and persists it', () async {
    final (service, preferences) = await create();
    final id = await service.getInstallationId();

    expect(id, matches(_uuidV4));
    expect(
      preferences.getString(InstallationIdentityService.storageKey),
      '"$id"',
    );
  });

  test(
    'returns the same identifier on repeated reads and new instances',
    () async {
      final (service, preferences) = await create();
      final first = await service.getInstallationId();
      expect(await service.getInstallationId(), first);

      final again = InstallationIdentityService(
        SharedPreferencesStoreService(preferences),
      );
      expect(await again.getInstallationId(), first);
    },
  );

  test('concurrent first reads produce one identifier', () async {
    final (service, _) = await create();
    final ids = await Future.wait([
      service.getInstallationId(),
      service.getInstallationId(),
    ]);
    expect(ids.toSet(), hasLength(1));
  });

  test('clearing storage produces a different identifier', () async {
    final (service, preferences) = await create();
    final first = await service.getInstallationId();
    await preferences.clear();
    expect(await service.getInstallationId(), isNot(first));
  });

  test('recovers from blank or corrupt stored values', () async {
    for (final corrupt in ['""', '"not-a-uuid"', '42', 'not json']) {
      final (service, _) = await create({
        InstallationIdentityService.storageKey: corrupt,
      });
      expect(
        await service.getInstallationId(),
        matches(_uuidV4),
        reason: corrupt,
      );
    }
  });

  test(
    'provider uses the shared preferences store and can be overridden',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      final id = await container
          .read(installationIdentityServiceProvider)
          .getInstallationId();
      expect(id, matches(_uuidV4));
    },
  );
}
