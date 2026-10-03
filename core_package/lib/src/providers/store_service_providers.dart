import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/storage/secure_store_service.dart';
import '../services/storage/shared_preferences_store_service.dart';
import '../services/storage/store_service.dart';
import 'shared_preferences_provider.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final sharedPreferencesStoreServiceProvider = Provider<StoreService>(
  (ref) => SharedPreferencesStoreService(ref.watch(sharedPreferencesProvider)),
);

final secureStoreServiceProvider = Provider<StoreService>(
  (ref) => SecureStoreService(ref.watch(flutterSecureStorageProvider)),
);
