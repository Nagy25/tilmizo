import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../providers/store_service_providers.dart';
import '../services/storage/store_service.dart';

/// A random per-installation identifier used to recognize this app install.
///
/// It is generated with a cryptographically secure random UUID and never
/// derived from hardware (no IMEI, Android ID, IDFV, MAC, serial number, or
/// advertising identifier). The backend stores only its SHA-256 hash. It is a
/// usability control, not hardware attestation.
class InstallationIdentityService {
  InstallationIdentityService(this._store, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  static const storageKey = 'telmizo.installation_id';
  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final StoreService _store;
  final Uuid _uuid;
  Future<String>? _pending;

  /// Returns the persisted identifier, creating it on first use. A blank or
  /// corrupt stored value is replaced with a new identifier.
  Future<String> getInstallationId() => _pending ??= _load().whenComplete(() {
    _pending = null;
  });

  Future<String> _load() async {
    Object? stored;
    try {
      stored = await _store.read(storageKey);
    } on FormatException {
      stored = null; // Corrupt value; replaced below.
    }
    if (stored is String && _uuidPattern.hasMatch(stored)) return stored;

    final created = _uuid.v4();
    await _store.write(storageKey, created);
    return created;
  }
}

final installationIdentityServiceProvider =
    Provider<InstallationIdentityService>(
      (ref) => InstallationIdentityService(
        ref.watch(sharedPreferencesStoreServiceProvider),
      ),
    );
