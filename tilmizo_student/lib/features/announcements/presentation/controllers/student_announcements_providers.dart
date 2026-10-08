import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../data/student_announcements_repository_impl.dart';
import '../../domain/student_announcement.dart';
import '../../domain/student_announcements_repository.dart';

@immutable
final class StudentAnnouncementsState {
  const StudentAnnouncementsState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<StudentAnnouncement> items;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  StudentAnnouncementsState copyWith({List<StudentAnnouncement>? items}) =>
      StudentAnnouncementsState(
        items: items ?? this.items,
        hasMore: hasMore,
        isLoadingMore: isLoadingMore,
        loadMoreFailed: loadMoreFailed,
      );
}

/// The approved group's announcements, newest first. Gated on the approved
/// session, so the loaded feed is dropped as soon as access changes.
final studentAnnouncementsProvider = AsyncNotifierProvider.autoDispose
    .family<StudentAnnouncementsController, StudentAnnouncementsState, String>(
      StudentAnnouncementsController.new,
    );

class StudentAnnouncementsController
    extends AsyncNotifier<StudentAnnouncementsState> {
  StudentAnnouncementsController(this.groupId);

  static const pageSize = 20;

  final String groupId;

  StudentAnnouncementsRepository get _repository =>
      ref.read(studentAnnouncementsRepositoryProvider);

  @override
  Future<StudentAnnouncementsState> build() async {
    await requireApprovedAccess(ref, groupId);
    final page = await ref
        .watch(studentAnnouncementsRepositoryProvider)
        .fetchAnnouncements(groupId, limit: pageSize);
    return StudentAnnouncementsState(items: page.items, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      StudentAnnouncementsState(
        items: current.items,
        hasMore: true,
        isLoadingMore: true,
      ),
    );
    try {
      final page = await _repository.fetchAnnouncements(
        groupId,
        offset: current.items.length,
        limit: pageSize,
      );
      if (!ref.mounted) return;
      final known = {for (final item in current.items) item.id};
      state = AsyncData(
        StudentAnnouncementsState(
          items: [
            ...current.items,
            ...page.items.where((item) => !known.contains(item.id)),
          ],
          hasMore: page.hasMore,
        ),
      );
    } on AppFailure {
      if (!ref.mounted) return;
      state = AsyncData(
        StudentAnnouncementsState(
          items: current.items,
          hasMore: true,
          loadMoreFailed: true,
        ),
      );
    }
  }

  /// Records the read through `mark_announcement_read` and only then marks
  /// the card as read. Returns the failure, or null on success.
  Future<AppFailure?> markRead(String announcementId) async {
    final DateTime readAt;
    try {
      readAt = await _repository.markRead(announcementId);
    } on AppFailure catch (failure) {
      return failure;
    }
    if (!ref.mounted) return null;
    if (state.value case final current?) {
      state = AsyncData(
        current.copyWith(
          items: [
            for (final item in current.items)
              item.id == announcementId ? item.markedRead(readAt) : item,
          ],
        ),
      );
    }
    return null;
  }
}

/// Reloads the feed, for example on pull-to-refresh, when the tab opens, or
/// when the app resumes.
void refreshStudentAnnouncements(WidgetRef ref, String groupId) =>
    ref.invalidate(studentAnnouncementsProvider(groupId));
