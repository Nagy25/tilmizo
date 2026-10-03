import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fails fast with the names of missing values', () {
    expect(
      () => SupabaseConfig.fromValues(url: '', publishableKey: ' '),
      throwsA(
        isA<MissingConfigurationError>()
            .having((e) => e.missingKeys, 'missingKeys', [
              'SUPABASE_URL',
              'SUPABASE_PUBLISHABLE_KEY',
            ])
            .having((e) => e.toString(), 'message', contains('env.local.json')),
      ),
    );
  });

  test('rejects a non-https URL', () {
    expect(
      () => SupabaseConfig.fromValues(
        url: 'http://example.supabase.co',
        publishableKey: 'sb_publishable_x',
      ),
      throwsArgumentError,
    );
  });

  test('accepts and trims valid values', () {
    final config = SupabaseConfig.fromValues(
      url: ' https://example.supabase.co ',
      publishableKey: ' sb_publishable_x ',
    );
    expect(config.url, 'https://example.supabase.co');
    expect(config.publishableKey, 'sb_publishable_x');
  });

  test('environment without defines is rejected', () {
    expect(
      SupabaseConfig.fromEnvironment,
      throwsA(isA<MissingConfigurationError>()),
    );
  });
}
