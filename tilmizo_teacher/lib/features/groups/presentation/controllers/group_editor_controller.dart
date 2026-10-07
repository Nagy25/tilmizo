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
    this.isArchiving = false,
    this.isSuspending = false,
    this.failure,
  });

  final bool isSubmitting;
  final bool isArchiving;

  /// A suspend or resume request is in flight.
  final bool isSuspending;
  final AppFailureType? failure;

  bool get isBusy => isSubmitting || isArchiving || isSuspending;
}

final groupEditorControllerProvider =
    NotifierProvider.autoDispose<GroupEditorController, GroupEditorState>(
      GroupEditorController.new,
    );

/// Create, update, and archive actions for one group form.
class GroupEditorController extends Notifier<GroupEditorState> {
  @override
  GroupEditorState build() => const GroupEditorState();

  GroupsController get _groups => ref.read(groupsControllerProvider.notifier);

  Future<TeacherGroup?> create(GroupDraft draft) =>
      _submit(() => _groups.create(draft));

  Future<TeacherGroup?> update(String groupId, GroupDraft draft) =>
      _submit(() => _groups.updateGroup(groupId, draft));

  Future<TeacherGroup?> archive(String groupId) async {
    if (state.isBusy) return null;
    state = const GroupEditorState(isArchiving: true);
    try {
      final archived = await _groups.archiveGroup(groupId);
      if (ref.mounted) state = const GroupEditorState();
      return archived;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = GroupEditorState(failure: failure.type);
      return null;
    }
  }

  /// Pauses or resumes the group; existing sessions and records are kept.
  Future<TeacherGroup?> setSuspended(
    String groupId, {
    required bool suspended,
  }) async {
    if (state.isBusy) return null;
    state = const GroupEditorState(isSuspending: true);
    try {
      final group = await _groups.setSuspended(groupId, suspended: suspended);
      if (ref.mounted) state = const GroupEditorState();
      return group;
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
