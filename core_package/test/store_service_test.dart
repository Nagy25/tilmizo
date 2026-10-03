import 'dart:convert';

import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _StoreHarness = ({
  StoreService service,
  Future<void> Function(String key, String value) writeRaw,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  _runStoreContract('SharedPreferencesStoreService', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    return (
      service: SharedPreferencesStoreService(preferences),
      writeRaw: preferences.setString,
    );
  });

  _runStoreContract('SecureStoreService', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    return (
      service: SecureStoreService(storage),
      writeRaw: (key, value) => storage.write(key: key, value: value),
    );
  });

  group('providers', () {
    test('create explicit standard and secure services', () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(sharedPreferencesStoreServiceProvider),
        isA<SharedPreferencesStoreService>(),
      );
      expect(
        container.read(secureStoreServiceProvider),
        isA<SecureStoreService>(),
      );
    });
  });
}

void _runStoreContract(
  String implementationName,
  Future<_StoreHarness> Function() createHarness,
) {
  group(implementationName, () {
    late _StoreHarness harness;

    setUp(() async {
      harness = await createHarness();
    });

    test('round-trips JSON-compatible values', () async {
      final values = <String, Object?>{
        'null': null,
        'string': 'Telmizo',
        'integer': 42,
        'double': 3.5,
        'boolean': true,
        'list': <Object?>['teacher', 2, false, null],
        'map': <String, Object?>{
          'subject': 'Mathematics',
          'grades': <int>[1, 2, 3],
        },
      };

      for (final entry in values.entries) {
        await harness.service.write(entry.key, entry.value);
        expect(await harness.service.read(entry.key), equals(entry.value));
        expect(await harness.service.containsKey(entry.key), isTrue);
      }
    });

    test('returns null and false for a missing key', () async {
      expect(await harness.service.read('missing'), isNull);
      expect(await harness.service.containsKey('missing'), isFalse);
    });

    test('deletes one value', () async {
      await harness.service.write('first', 1);
      await harness.service.write('second', 2);

      await harness.service.delete('first');

      expect(await harness.service.containsKey('first'), isFalse);
      expect(await harness.service.read('second'), 2);
    });

    test('clears the complete backend', () async {
      await harness.service.write('first', 1);
      await harness.service.write('second', 2);
      await harness.writeRaw('raw', jsonEncode('outside the service'));

      await harness.service.clear();

      expect(await harness.service.containsKey('first'), isFalse);
      expect(await harness.service.containsKey('second'), isFalse);
      expect(await harness.service.containsKey('raw'), isFalse);
    });

    test('rejects blank keys for keyed operations', () async {
      await expectLater(
        harness.service.write('  ', 'value'),
        throwsArgumentError,
      );
      await expectLater(harness.service.read(''), throwsArgumentError);
      await expectLater(harness.service.containsKey('\t'), throwsArgumentError);
      await expectLater(harness.service.delete('\n'), throwsArgumentError);
    });

    test('propagates unsupported JSON encoding failures', () async {
      await expectLater(
        harness.service.write('unsupported', DateTime(2026)),
        throwsA(isA<JsonUnsupportedObjectError>()),
      );
    });

    test('propagates malformed JSON decoding failures', () async {
      await harness.writeRaw('malformed', 'not-json');

      await expectLater(
        harness.service.read('malformed'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
