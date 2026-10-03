import 'package:shared_preferences/shared_preferences.dart';

import 'store_json_codec.dart';
import 'store_service.dart';

final class SharedPreferencesStoreService implements StoreService {
  SharedPreferencesStoreService(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<void> write(String key, Object? value) async {
    final didSave = await _preferences.setString(
      validateStoreKey(key),
      encodeStoreValue(value),
    );

    if (!didSave) {
      throw StateError('SharedPreferences could not save the value');
    }
  }

  @override
  Future<Object?> read(String key) async {
    final value = _preferences.getString(validateStoreKey(key));
    return value == null ? null : decodeStoreValue(value);
  }

  @override
  Future<bool> containsKey(String key) async {
    return _preferences.containsKey(validateStoreKey(key));
  }

  @override
  Future<void> delete(String key) async {
    final didDelete = await _preferences.remove(validateStoreKey(key));
    if (!didDelete) {
      throw StateError('SharedPreferences could not delete the value');
    }
  }

  @override
  Future<void> clear() async {
    final didClear = await _preferences.clear();
    if (!didClear) {
      throw StateError('SharedPreferences could not clear its values');
    }
  }
}
