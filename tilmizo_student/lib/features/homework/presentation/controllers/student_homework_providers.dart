import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../group_access/domain/student_access_state.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../data/student_homework_repository_impl.dart';

typedef GroupHomeworkKey = ({String groupId, String id});

/// The approved group's homework. Gated on the approved session, so loaded
/// data is dropped as soon as access is suspended, removed or replaced.
final studentGroupHomeworkProvider = FutureProvider.autoDispose
    .family<List<Homework>, String>((ref, groupId) async {
      await requireApprovedAccess(ref, groupId);
      return ref
          .watch(studentHomeworkRepositoryProvider)
          .fetchGroupHomework(groupId);
    });

/// Homework of one session; [GroupHomeworkKey.id] is the session id.
final studentSessionHomeworkProvider = FutureProvider.autoDispose
    .family<List<Homework>, GroupHomeworkKey>((ref, key) async {
      await requireApprovedAccess(ref, key.groupId);
      return ref
          .watch(studentHomeworkRepositoryProvider)
          .fetchSessionHomework(key.id);
    });

/// One homework; [GroupHomeworkKey.id] is the homework id.
final studentHomeworkProvider = FutureProvider.autoDispose
    .family<Homework, GroupHomeworkKey>((ref, key) async {
      await requireApprovedAccess(ref, key.groupId);
      final homework = await ref
          .watch(studentHomeworkRepositoryProvider)
          .fetchHomework(key.id);
      if (homework == null || homework.groupId != key.groupId) {
        throw const AppFailure(AppFailureType.notFound);
      }
      return homework;
    });

final studentHomeworkAttachmentsProvider = FutureProvider.autoDispose
    .family<List<GroupResource>, GroupHomeworkKey>((ref, key) async {
      final homework = await ref.watch(studentHomeworkProvider(key).future);
      return ref
          .watch(studentHomeworkRepositoryProvider)
          .fetchResources(homework.resourceIds);
    });

final myHomeworkSubmissionProvider = FutureProvider.autoDispose
    .family<HomeworkLinkSubmission?, GroupHomeworkKey>((ref, key) async {
      await requireApprovedAccess(ref, key.groupId);
      return ref
          .watch(studentHomeworkRepositoryProvider)
          .fetchMySubmission(key.id);
    });

/// Reloads a group's homework views, for example on pull-to-refresh, when
/// the tab opens, or when the app resumes.
void refreshStudentHomework(WidgetRef ref, String groupId) {
  ref
    ..invalidate(studentGroupHomeworkProvider(groupId))
    ..invalidate(studentSessionHomeworkProvider)
    ..invalidate(studentHomeworkProvider)
    ..invalidate(studentHomeworkAttachmentsProvider)
    ..invalidate(myHomeworkSubmissionProvider);
}

enum LinkSubmitOutcome {
  saved,
  invalidLink,

  /// The Cairo due date passed on the server, even if the device clock
  /// still shows it open.
  closed,

  /// This session is no longer approved for the group.
  accessLost,
  failed,
}

@immutable
final class LinkSubmitState {
  const LinkSubmitState({this.isSaving = false, this.failure});

  final bool isSaving;
  final AppFailureType? failure;
}

final linkSubmitControllerProvider = NotifierProvider.autoDispose
    .family<LinkSubmitController, LinkSubmitState, GroupHomeworkKey>(
      LinkSubmitController.new,
    );

/// Saves the student's link through `submit_homework_link`.
class LinkSubmitController extends Notifier<LinkSubmitState> {
  LinkSubmitController(this.key);

  final GroupHomeworkKey key;

  @override
  LinkSubmitState build() => const LinkSubmitState();

  Future<LinkSubmitOutcome> submit(String url) async {
    if (state.isSaving) return LinkSubmitOutcome.failed;
    state = const LinkSubmitState(isSaving: true);
    final container = ref.container;
    var outcome = LinkSubmitOutcome.failed;
    AppFailureType? failure;
    try {
      await ref.read(studentHomeworkRepositoryProvider).submitLink(key.id, url);
      outcome = LinkSubmitOutcome.saved;
    } on AppFailure catch (error) {
      failure = error.type;
      outcome = switch (error.type) {
        AppFailureType.invalidInput => LinkSubmitOutcome.invalidLink,
        AppFailureType.notEligible => await _closedOrAccessLost(container),
        _ => LinkSubmitOutcome.failed,
      };
    }
    container
      ..invalidate(myHomeworkSubmissionProvider(key))
      ..invalidate(studentHomeworkProvider(key));
    if (ref.mounted) state = LinkSubmitState(failure: failure);
    return outcome;
  }

  /// The RPC rejects both cases with one code: re-check access with the
  /// backend to tell them apart.
  Future<LinkSubmitOutcome> _closedOrAccessLost(
    ProviderContainer container,
  ) async {
    try {
      final entries = await container
          .read(groupAccessOverviewProvider.notifier)
          .refresh();
      return findEntry(entries, key.groupId)?.state ==
              StudentAccessState.approved
          ? LinkSubmitOutcome.closed
          : LinkSubmitOutcome.accessLost;
    } on AppFailure {
      return LinkSubmitOutcome.failed;
    }
  }
}
