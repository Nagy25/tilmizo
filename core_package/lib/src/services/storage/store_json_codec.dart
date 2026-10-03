import 'dart:convert';

String encodeStoreValue(Object? value) => jsonEncode(value);

Object? decodeStoreValue(String value) => jsonDecode(value);

String validateStoreKey(String key) {
  if (key.trim().isEmpty) {
    throw ArgumentError.value(key, 'key', 'Store keys cannot be blank');
  }

  return key;
}
