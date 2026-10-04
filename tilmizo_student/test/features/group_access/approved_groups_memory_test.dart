import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilmizo_student/features/group_access/data/approved_groups_memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ApprovedGroupsMemory> create([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return ApprovedGroupsMemory(
      SharedPreferencesStoreService(await SharedPreferences.getInstance()),
    );
  }

  test('remembers, merges, and clears group IDs', () async {
    final memory = await create();
    await memory.remember(['g1']);
    await memory.remember(['g2', 'g1']);
    expect(await memory.read(), {'g1', 'g2'});
    await memory.clear();
    expect(await memory.read(), isEmpty);
  });

  test('treats corrupt stored values as empty', () async {
    for (final corrupt in ['not json', '"text"', '42']) {
      final memory = await create({ApprovedGroupsMemory.storageKey: corrupt});
      expect(await memory.read(), isEmpty, reason: corrupt);
    }
  });
}
