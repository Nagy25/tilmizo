import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'store_json_codec.dart';
import 'store_service.dart';

final class SecureStoreService implements StoreService {
  SecureStoreService(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, Object? value) async {
    await _storage.write(
      key: validateStoreKey(key),
      value: encodeStoreValue(value),
    );
  }

  @override
  Future<Object?> read(String key) async {
    final value = await _storage.read(key: validateStoreKey(key));
    return value == null ? null : decodeStoreValue(value);
  }

  @override
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: validateStoreKey(key));
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: validateStoreKey(key));
  }

  @override
  Future<void> clear() => _storage.deleteAll();
}
