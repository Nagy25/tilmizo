import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageSelectionStorageProvider = Provider<LanguageSelectionStorage>(
  (ref) => LanguageSelectionStorage(ref.watch(sharedPreferencesProvider)),
);

class LanguageSelectionStorage {
  LanguageSelectionStorage(this._preferences);

  static const _hasSelectedLanguageKey = 'has_selected_language';

  final SharedPreferences _preferences;

  bool get hasSelectedLanguage =>
      _preferences.getBool(_hasSelectedLanguageKey) ?? false;

  Future<bool> setHasSelectedLanguage(bool value) {
    return _preferences.setBool(_hasSelectedLanguageKey, value);
  }
}
