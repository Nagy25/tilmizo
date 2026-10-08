import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../groups/presentation/controllers/groups_controller.dart';
import '../../data/announcements_repository_impl.dart';
import '../../domain/announcements_repository.dart';

@immutable
final class AnnouncementsFeedState {
  const AnnouncementsFeedState({
    required this.announcements,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<Announcement> announcements;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
}

/// A group's announcements, newest first, paged by offset. Shared by the
/// group-details tile and the feed screen.
final announcementsFeedProvider = AsyncNotifierProvider.autoDispose
    .family<AnnouncementsFeedController, AnnouncementsFeedState, String>(
      AnnouncementsFeedController.new,
    );

class AnnouncementsFeedController
    extends AsyncNotifier<AnnouncementsFeedState> {
  AnnouncementsFeedController(this.groupId);

  static const pageSize = 20;

  final String groupId;

  AnnouncementsRepository get _repository =>
      ref.read(announcementsRepositoryProvider);

  @override
  Future<AnnouncementsFeedState> build() async {
    final page = await ref
        .watch(announcementsRepositoryProvider)
        .fetchAnnouncements(groupId, limit: pageSize);
    return AnnouncementsFeedState(
      announcements: page.announcements,
      hasMore: page.hasMore,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      AnnouncementsFeedState(
        announcements: current.announcements,
        hasMore: true,
        isLoadingMore: true,
      ),
    );
    try {
      final page = await _repository.fetchAnnouncements(
        groupId,
        offset: current.announcements.length,
        limit: pageSize,
      );
      if (!ref.mounted) return;
      final known = {for (final item in current.announcements) item.id};
      state = AsyncData(
        AnnouncementsFeedState(
          announcements: [
            ...current.announcements,
            ...page.announcements.where((a) => !known.contains(a.id)),
          ],
          hasMore: page.hasMore,
        ),
      );
    } on AppFailure {
      if (!ref.mounted) return;
      state = AsyncData(
        AnnouncementsFeedState(
          announcements: current.announcements,
          hasMore: true,
          loadMoreFailed: true,
        ),
      );
    }
  }

  /// Publishes through `create_announcement`; the backend notifies students.
  Future<void> create(AnnouncementDraft draft) =>
      _write(() => _repository.createAnnouncement(groupId, draft));

  Future<void> delete(String announcementId) =>
      _write(() => _repository.deleteAnnouncement(announcementId));

  /// Runs one RPC and reloads the feed after success. A rejection that
  /// means the server moved on (the announcement is gone, or the group was
  /// archived or suspended elsewhere) reloads too, then rethrows.
  Future<void> _write(Future<void> Function() write) async {
    final container = ref.container;
    try {
      await write();
    } on AppFailure catch (failure) {
      if (failure.type == AppFailureType.notEligible) {
        container.invalidate(groupDetailsProvider(groupId));
      }
      if (failure.type == AppFailureType.notEligible ||
          failure.type == AppFailureType.notFound) {
        container.invalidate(announcementsFeedProvider(groupId));
      }
      rethrow;
    }
    container.invalidate(announcementsFeedProvider(groupId));
  }
}
