import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/classes_repository_impl.dart';
import '../../domain/class_session.dart';
import '../../domain/classes_repository.dart';
import '../../domain/schedule_entry.dart';

typedef SessionsQuery = ({String? groupId, SessionsView view});

@immutable
final class SessionsListState {
  const SessionsListState({
    required this.sessions,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  final List<ClassSession> sessions;
  final bool hasMore;
  final bool isLoadingMore;
  final AppFailureType? loadMoreFailure;
}

/// A paged session list for one group (or all groups) and view.
final sessionsListProvider = AsyncNotifierProvider.autoDispose
    .family<SessionsListController, SessionsListState, SessionsQuery>(
      SessionsListController.new,
    );

class SessionsListController extends AsyncNotifier<SessionsListState> {
  SessionsListController(this.query);

  static const pageSize = 30;

  final SessionsQuery query;

  /// Pages share one cutoff so sessions do not shift between views.
  late DateTime _now;

  ClassesRepository get _repository => ref.read(classesRepositoryProvider);

  @override
  Future<SessionsListState> build() async {
    _now = ref.read(clockProvider)();
    final page = await ref
        .watch(classesRepositoryProvider)
        .fetchSessions(
          view: query.view,
          now: _now,
          groupId: query.groupId,
          limit: pageSize,
        );
    return SessionsListState(sessions: page.sessions, hasMore: page.hasMore);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      SessionsListState(
        sessions: current.sessions,
        hasMore: true,
        isLoadingMore: true,
      ),
    );
    try {
      final page = await _repository.fetchSessions(
        view: query.view,
        now: _now,
        groupId: query.groupId,
        offset: current.sessions.length,
        limit: pageSize,
      );
      if (!ref.mounted) return;
      final known = {for (final session in current.sessions) session.id};
      state = AsyncData(
        SessionsListState(
          sessions: [
            ...current.sessions,
            ...page.sessions.where((s) => !known.contains(s.id)),
          ],
          hasMore: page.hasMore,
        ),
      );
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(
        SessionsListState(
          sessions: current.sessions,
          hasMore: true,
          loadMoreFailure: failure.type,
        ),
      );
    }
  }
}

/// The next scheduled session that has not ended, for home summaries.
final nextSessionProvider = FutureProvider.autoDispose
    .family<ClassSession?, String?>(
      (ref, groupId) => ref
          .watch(classesRepositoryProvider)
          .fetchNextSession(now: ref.read(clockProvider)(), groupId: groupId),
    );

final sessionDetailsProvider = FutureProvider.autoDispose
    .family<ClassSession, String>(
      (ref, sessionId) =>
          ref.watch(classesRepositoryProvider).fetchSession(sessionId),
    );

final groupScheduleProvider = FutureProvider.autoDispose
    .family<List<ScheduleEntry>, String>(
      (ref, groupId) =>
          ref.watch(classesRepositoryProvider).fetchScheduleEntries(groupId),
    );

final scheduleEntryProvider = FutureProvider.autoDispose
    .family<ScheduleEntry, String>(
      (ref, entryId) =>
          ref.watch(classesRepositoryProvider).fetchScheduleEntry(entryId),
    );

/// Reloads every session view after a write.
void refreshSessionViews(Ref ref, {String? sessionId}) {
  ref.invalidate(sessionsListProvider);
  ref.invalidate(nextSessionProvider);
  if (sessionId != null) ref.invalidate(sessionDetailsProvider(sessionId));
}
