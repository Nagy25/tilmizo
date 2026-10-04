import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/groups_repository_impl.dart';
import '../../domain/group_draft.dart';
import '../../domain/teacher_group.dart';

/// The authenticated teacher's groups, newest first.
final groupsControllerProvider =
    AsyncNotifierProvider<GroupsController, List<TeacherGroup>>(
      GroupsController.new,
    );

class GroupsController extends AsyncNotifier<List<TeacherGroup>> {
  @override
  Future<List<TeacherGroup>> build() =>
      ref.watch(groupsRepositoryProvider).fetchOwnGroups();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<TeacherGroup> create(GroupDraft draft) async {
    final created = await ref.read(groupsRepositoryProvider).createGroup(draft);
    state = AsyncData([created, ..._current.where((g) => g.id != created.id)]);
    await _syncQuietly();
    return created;
  }

  Future<TeacherGroup> updateGroup(String groupId, GroupDraft draft) async {
    try {
      final updated = await ref
          .read(groupsRepositoryProvider)
          .updateGroup(groupId, draft);
      state = AsyncData([
        for (final group in _current) group.id == groupId ? updated : group,
      ]);
      return updated;
    } on AppFailure catch (failure) {
      if (failure.type == AppFailureType.notFound) _removeLocally(groupId);
      rethrow;
    }
  }

  /// Deletes a group and returns whether any groups remain.
  Future<bool> delete(String groupId) async {
    await ref.read(groupsRepositoryProvider).deleteGroup(groupId);
    _removeLocally(groupId);
    await _syncQuietly();
    return _current.isNotEmpty;
  }

  List<TeacherGroup> get _current => state.value ?? const [];

  void _removeLocally(String groupId) {
    state = AsyncData(_current.where((g) => g.id != groupId).toList());
  }

  /// Reconciles with the server after a mutation, keeping the local result
  /// when the refresh itself fails.
  Future<void> _syncQuietly() async {
    try {
      final fresh = await ref.read(groupsRepositoryProvider).fetchOwnGroups();
      if (ref.mounted) state = AsyncData(fresh);
    } on AppFailure {
      // The mutation succeeded; the local state is still accurate.
    }
  }
}

/// A single owned group, fetched fresh so edits made elsewhere are visible.
final groupDetailsProvider = FutureProvider.autoDispose
    .family<TeacherGroup, String>(
      (ref, groupId) =>
          ref.watch(groupsRepositoryProvider).fetchOwnGroup(groupId),
    );
