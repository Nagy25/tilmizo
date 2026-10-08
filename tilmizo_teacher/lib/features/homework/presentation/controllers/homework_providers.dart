import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../groups/presentation/controllers/groups_controller.dart';
import '../../data/homework_repository_impl.dart';
import '../../domain/homework_repository.dart';

/// A group's homework, newest first.
final groupHomeworkProvider = FutureProvider.autoDispose
    .family<List<Homework>, String>(
      (ref, groupId) =>
          ref.watch(homeworkRepositoryProvider).fetchGroupHomework(groupId),
    );

/// The homework of one session, newest first.
final sessionHomeworkProvider = FutureProvider.autoDispose
    .family<List<Homework>, String>(
      (ref, sessionId) =>
          ref.watch(homeworkRepositoryProvider).fetchSessionHomework(sessionId),
    );

final homeworkDetailsProvider = FutureProvider.autoDispose
    .family<Homework, String>((ref, homeworkId) async {
      final homework = await ref
          .watch(homeworkRepositoryProvider)
          .fetchHomework(homeworkId);
      if (homework == null) throw const AppFailure(AppFailureType.notFound);
      return homework;
    });

/// Resource rows of a homework's attachments, in attachment order.
final homeworkAttachmentsProvider = FutureProvider.autoDispose
    .family<List<GroupResource>, String>((ref, homeworkId) async {
      final homework = await ref.watch(
        homeworkDetailsProvider(homeworkId).future,
      );
      return ref
          .watch(homeworkRepositoryProvider)
          .fetchResources(homework.resourceIds);
    });

final homeworkSubmissionsProvider = FutureProvider.autoDispose
    .family<List<TeacherHomeworkSubmission>, String>(
      (ref, homeworkId) =>
          ref.watch(homeworkRepositoryProvider).fetchSubmissions(homeworkId),
    );

typedef AttachableQuery = ({String groupId, String sessionId});

/// Uploaded Resources that `create_homework` accepts for one session.
final attachableResourcesProvider = FutureProvider.autoDispose
    .family<List<GroupResource>, AttachableQuery>(
      (ref, query) => ref
          .watch(homeworkRepositoryProvider)
          .fetchAttachableResources(
            groupId: query.groupId,
            sessionId: query.sessionId,
          ),
    );

enum HomeworkAction { create, delete }

@immutable
final class HomeworkActionState {
  const HomeworkActionState({this.pending, this.failure});

  final HomeworkAction? pending;

  /// A [HomeworkFailure] or [AppFailure] from the last write.
  final Exception? failure;

  bool get isBusy => pending != null;
}

final homeworkActionsProvider =
    NotifierProvider.autoDispose<
      HomeworkActionsController,
      HomeworkActionState
    >(HomeworkActionsController.new);

/// Homework RPC writes for one screen. Each method returns whether it
/// succeeded and records a failure in [HomeworkActionState.failure].
class HomeworkActionsController extends Notifier<HomeworkActionState> {
  @override
  HomeworkActionState build() => const HomeworkActionState();

  HomeworkRepository get _repository => ref.read(homeworkRepositoryProvider);

  Future<Homework?> create({
    required String groupId,
    required HomeworkDraft draft,
  }) async {
    Homework? created;
    await _run(
      HomeworkAction.create,
      groupId: groupId,
      sessionId: draft.sessionId,
      () async => created = await _repository.createHomework(draft),
    );
    return created;
  }

  /// Deletes the homework; its attached Resources are left untouched.
  Future<bool> delete(Homework homework) => _run(
    HomeworkAction.delete,
    groupId: homework.groupId,
    sessionId: homework.sessionId,
    homeworkId: homework.id,
    () => _repository.deleteHomework(homework.id),
  );

  Future<bool> _run(
    HomeworkAction action,
    Future<void> Function() write, {
    required String groupId,
    required String sessionId,
    String? homeworkId,
  }) async {
    if (state.isBusy) return false;
    final container = ref.container;
    state = HomeworkActionState(pending: action);
    try {
      await write();
      if (ref.mounted) state = const HomeworkActionState();
      return true;
    } on Exception catch (failure) {
      if (failure case HomeworkFailure(
        reason: HomeworkFailureReason.groupNotWritable,
      )) {
        container.invalidate(groupDetailsProvider(groupId));
      }
      if (ref.mounted) state = HomeworkActionState(failure: failure);
      return false;
    } finally {
      // A rejection may also mean the server moved on, for example a
      // homework another device already deleted.
      container
        ..invalidate(groupHomeworkProvider(groupId))
        ..invalidate(sessionHomeworkProvider(sessionId));
      if (homeworkId != null) {
        container.invalidate(homeworkDetailsProvider(homeworkId));
      }
    }
  }
}
