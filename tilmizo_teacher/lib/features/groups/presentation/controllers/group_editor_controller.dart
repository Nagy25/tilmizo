import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/group_draft.dart';
import '../../domain/teacher_group.dart';
import 'groups_controller.dart';

@immutable
final class GroupEditorState {
  const GroupEditorState({
    this.isSubmitting = false,
    this.isDeleting = false,
    this.failure,
  });

  final bool isSubmitting;
  final bool isDeleting;
  final AppFailureType? failure;

  bool get isBusy => isSubmitting || isDeleting;
}

final groupEditorControllerProvider =
    NotifierProvider.autoDispose<GroupEditorController, GroupEditorState>(
      GroupEditorController.new,
    );

/// Create, update, and delete actions for one group form.
class GroupEditorController extends Notifier<GroupEditorState> {
  @override
  GroupEditorState build() => const GroupEditorState();

  GroupsController get _groups => ref.read(groupsControllerProvider.notifier);

  Future<TeacherGroup?> create(GroupDraft draft) =>
      _submit(() => _groups.create(draft));

  Future<TeacherGroup?> update(String groupId, GroupDraft draft) =>
      _submit(() => _groups.updateGroup(groupId, draft));

  /// Returns whether groups remain, or `null` when deletion failed.
  Future<bool?> delete(String groupId) async {
    if (state.isBusy) return null;
    state = const GroupEditorState(isDeleting: true);
    try {
      final hasRemaining = await _groups.delete(groupId);
      if (ref.mounted) state = const GroupEditorState();
      return hasRemaining;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = GroupEditorState(failure: failure.type);
      return null;
    }
  }

  void clearFailure() {
    if (state.failure != null) state = const GroupEditorState();
  }

  Future<TeacherGroup?> _submit(Future<TeacherGroup> Function() action) async {
    if (state.isBusy) return null;
    state = const GroupEditorState(isSubmitting: true);
    try {
      final group = await action();
      if (ref.mounted) state = const GroupEditorState();
      return group;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = GroupEditorState(failure: failure.type);
      return null;
    }
  }
}
