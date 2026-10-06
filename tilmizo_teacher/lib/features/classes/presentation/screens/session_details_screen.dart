import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/class_session.dart';
import '../controllers/classes_editor_controller.dart';
import '../controllers/classes_providers.dart';
import '../formatting/session_formatting.dart';
import '../widgets/session_actions.dart';
import '../widgets/session_dialogs.dart';
import '../widgets/session_info_cards.dart';

@RoutePage()
class SessionDetailsScreen extends ConsumerWidget {
  const SessionDetailsScreen({
    super.key,
    @PathParam('sessionId') required this.sessionId,
  });

  final String sessionId;

  Future<void> _editNotes(
    BuildContext context,
    WidgetRef ref,
    ClassSession session,
  ) async {
    final notes = await showSessionNotesSheet(context, session.notes);
    if (notes == null || trimToNull(notes) == session.notes) return;
    final updated = await ref
        .read(classesEditorControllerProvider.notifier)
        .updateNotes(session.id, notes);
    if (updated != null && context.mounted) {
      showTelmizoSnackBar(context, LocaleKeys.session_notes_saved.tr());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionDetailsProvider(sessionId));
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.session_details_title.tr(),
        subtitle: session.value?.group.name,
        showBack: true,
      ),
      body: session.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) {
          final notFound = failureTypeOf(error) == AppFailureType.notFound;
          return TelmizoErrorView(
            icon: notFound ? Icons.search_off : Icons.cloud_off_outlined,
            title:
                (notFound
                        ? LocaleKeys.session_not_found_title
                        : LocaleKeys.session_load_error_title)
                    .tr(),
            message: classesErrorMessage(error),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(sessionDetailsProvider(sessionId)),
          );
        },
        data: (session) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(sessionDetailsProvider(sessionId).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              TelmizoSpacing.margin,
              TelmizoSpacing.lg,
              TelmizoSpacing.margin,
              TelmizoSpacing.xl,
            ),
            children: [
              SessionHeaderCard(session: session, now: now),
              if (!session.group.isActive) ...[
                const SizedBox(height: TelmizoSpacing.md),
                TelmizoInlineMessage(
                  message: LocaleKeys.session_read_only_archived.tr(),
                  tone: TelmizoMessageTone.info,
                ),
              ],
              const SizedBox(height: TelmizoSpacing.md),
              SessionWhenCard(session: session),
              const SizedBox(height: TelmizoSpacing.md),
              SessionLocationCard(session: session),
              const SizedBox(height: TelmizoSpacing.md),
              SessionNotesCard(
                session: session,
                onEdit: session.canEditNotes
                    ? () => _editNotes(context, ref, session)
                    : null,
              ),
              if (session.canEdit) ...[
                const SizedBox(height: TelmizoSpacing.md),
                TelmizoInlineMessage(
                  message: LocaleKeys.session_only_this_notice.tr(),
                  tone: TelmizoMessageTone.info,
                ),
              ],
              const SizedBox(height: TelmizoSpacing.lg),
              SessionActions(session: session, now: now),
            ],
          ),
        ),
      ),
    );
  }
}
