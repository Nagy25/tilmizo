import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../domain/classes_repository.dart';
import '../controllers/classes_providers.dart';
import 'classes_empty_view.dart';
import 'session_card.dart';

/// The sessions of one view with loading, error, empty, and paging states.
class SessionsListSection extends ConsumerWidget {
  const SessionsListSection({super.key, required this.query});

  final SessionsQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsListProvider(query));
    final now = ref.watch(clockProvider)();
    return sessions.when(
      skipLoadingOnRefresh: true,
      loading: () => const Padding(
        padding: EdgeInsets.all(TelmizoSpacing.xl),
        child: TelmizoLoadingView(),
      ),
      error: (error, _) => TelmizoErrorView(
        title: LocaleKeys.classes_load_error_title.tr(),
        message: appFailureMessage(failureTypeOf(error)),
        retryLabel: LocaleKeys.common_retry.tr(),
        onRetry: () => ref.invalidate(sessionsListProvider(query)),
      ),
      data: (state) {
        if (state.sessions.isEmpty) return _EmptyState(view: query.view);
        final controller = ref.read(sessionsListProvider(query).notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final session in state.sessions) ...[
              SessionCard(
                session: session,
                now: now,
                onTap: () => context.router.push(
                  SessionDetailsRoute(sessionId: session.id),
                ),
                onAttendance:
                    query.view == SessionsView.upcoming &&
                        session.canTakeAttendance(now)
                    ? () => context.router.push(
                        AttendanceRoute(sessionId: session.id),
                      )
                    : null,
              ),
              const SizedBox(height: TelmizoSpacing.md),
            ],
            if (state.loadMoreFailure case final failure?)
              Padding(
                padding: const EdgeInsets.only(bottom: TelmizoSpacing.sm),
                child: TelmizoInlineMessage(
                  message: appFailureMessage(failure),
                ),
              ),
            if (state.hasMore)
              TelmizoSecondaryButton(
                label: LocaleKeys.classes_load_more.tr(),
                icon: Icons.expand_more,
                isLoading: state.isLoadingMore,
                onPressed: controller.loadMore,
              ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.view});

  final SessionsView view;

  @override
  Widget build(BuildContext context) => switch (view) {
    SessionsView.upcoming => ClassesEmptyView(
      icon: Icons.event_note_outlined,
      title: LocaleKeys.classes_empty_upcoming_title.tr(),
      body: LocaleKeys.classes_empty_upcoming_body.tr(),
    ),
    SessionsView.past => ClassesEmptyView(
      icon: Icons.history,
      title: LocaleKeys.classes_empty_past_title.tr(),
      body: LocaleKeys.classes_empty_past_body.tr(),
    ),
    SessionsView.cancelled => ClassesEmptyView(
      icon: Icons.event_busy_outlined,
      title: LocaleKeys.classes_empty_cancelled_title.tr(),
      body: LocaleKeys.classes_empty_cancelled_body.tr(),
    ),
  };
}
