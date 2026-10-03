/// Asynchronous storage for JSON-compatible values.
///
/// A missing key and a stored JSON `null` both return `null`. Use
/// [containsKey] when that distinction matters.
abstract interface class StoreService {
  Future<void> write(String key, Object? value);

  Future<Object?> read(String key);

  Future<bool> containsKey(String key);

  Future<void> delete(String key);

  /// Removes every value from the underlying storage backend.
  Future<void> clear();
}
