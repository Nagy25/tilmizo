import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Group IDs whose access was approved on this installation.
///
/// The overview reports both "this installation was replaced" and "this is a
/// new device" as `different_device`; this local memory picks the wording.
/// It is a display hint only and never grants or implies access.
class ApprovedGroupsMemory {
  ApprovedGroupsMemory(this._store);

  static const storageKey = 'telmizo.approved_group_ids';

  final StoreService _store;

  Future<Set<String>> read() async {
    try {
      final stored = await _store.read(storageKey);
      if (stored is List) return stored.whereType<String>().toSet();
    } on FormatException {
      // Corrupt value: treat as empty.
    }
    return <String>{};
  }

  Future<void> remember(Iterable<String> groupIds) async {
    final ids = groupIds.toSet();
    if (ids.isEmpty) return;
    final known = await read();
    if (known.containsAll(ids)) return;
    await _store.write(storageKey, ({...known, ...ids}).toList()..sort());
  }

  /// Forgets everything, for example on sign-out.
  Future<void> clear() async {
    if (await _store.containsKey(storageKey)) await _store.delete(storageKey);
  }
}

final approvedGroupsMemoryProvider = Provider<ApprovedGroupsMemory>(
  (ref) =>
      ApprovedGroupsMemory(ref.watch(sharedPreferencesStoreServiceProvider)),
);
