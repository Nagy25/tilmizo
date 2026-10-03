import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the application-owned [SharedPreferences] instance.
///
/// Each application must initialize SharedPreferences before `runApp` and
/// override this provider at the root [ProviderScope].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});
