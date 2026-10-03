import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown at startup when required compile-time configuration is missing.
final class MissingConfigurationError extends Error {
  MissingConfigurationError(this.missingKeys);

  final List<String> missingKeys;

  @override
  String toString() =>
      'Missing compile-time configuration: ${missingKeys.join(', ')}. '
      'Run with --dart-define-from-file=config/env.local.json '
      '(see config/env.example.json).';
}

/// Supabase connection values supplied with `--dart-define`.
final class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  /// Reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`, failing fast with a
  /// developer-readable error when either is absent.
  factory SupabaseConfig.fromEnvironment() => SupabaseConfig.fromValues(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  factory SupabaseConfig.fromValues({
    required String url,
    required String publishableKey,
  }) {
    final missing = [
      if (url.trim().isEmpty) 'SUPABASE_URL',
      if (publishableKey.trim().isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    ];
    if (missing.isNotEmpty) throw MissingConfigurationError(missing);
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.isScheme('https') || uri.host.isEmpty) {
      throw ArgumentError.value(url, 'SUPABASE_URL', 'Must be an https URL');
    }
    return SupabaseConfig(
      url: url.trim(),
      publishableKey: publishableKey.trim(),
    );
  }

  final String url;
  final String publishableKey;
}

/// Initializes Supabase and restores any persisted session.
Future<void> initializeSupabase(SupabaseConfig config) async {
  await Supabase.initialize(
    url: config.url,
    publishableKey: config.publishableKey,
  );
}
