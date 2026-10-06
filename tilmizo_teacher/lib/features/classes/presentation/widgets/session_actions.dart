import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../domain/class_session.dart';
import '../controllers/classes_editor_controller.dart';
import '../formatting/session_formatting.dart';
import 'session_dialogs.dart';

/// The actions the backend and session state allow at [now].
class SessionActions extends ConsumerWidget {
  const SessionActions({super.key, required this.session, required this.now});

  final ClassSession session;
  final DateTime now;

  Future<void> _run(
    BuildContext context,
    Future<ClassSession?> Function() action,
    String success,
  ) async {
    final result = await action();
    if (result != null && context.mounted) {
      showTelmizoSnackBar(context, success);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(classesEditorControllerProvider);
    final editor = ref.read(classesEditorControllerProvider.notifier);
    final enabled = !state.isBusy;
    final textTheme = context.textTheme;
    final canAttend = session.canTakeAttendance(now);
    final attendanceLocked =
        session.group.isActive &&
        !session.isCancelled &&
        session.isBeforeAttendanceDay(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKeys.session_actions_title.tr(),
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: TelmizoSpacing.md),
        TelmizoPrimaryButton(
          key: const Key('session-attendance'),
          label:
              (canAttend
                      ? LocaleKeys.session_take_attendance
                      : LocaleKeys.session_view_attendance)
                  .tr(),
          icon: Icons.playlist_add_check,
          onPressed: attendanceLocked
              ? null
              : () =>
                    context.router.push(AttendanceRoute(sessionId: session.id)),
        ),
        if (attendanceLocked) ...[
          const SizedBox(height: TelmizoSpacing.xs),
          Text(
            LocaleKeys.session_attendance_not_yet.tr(),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ],
        if (session.canEdit) ...[
          const SizedBox(height: TelmizoSpacing.md),
          TelmizoSecondaryButton(
            key: const Key('session-edit'),
            label: LocaleKeys.session_edit_action.tr(),
            icon: Icons.update,
            onPressed: enabled
                ? () => context.router.push(
                    SessionEditRoute(sessionId: session.id),
                  )
                : null,
          ),
        ],
        if (session.canComplete(now)) ...[
          const SizedBox(height: TelmizoSpacing.md),
          TelmizoSecondaryButton(
            key: const Key('session-complete'),
            label: LocaleKeys.session_complete_action.tr(),
            icon: Icons.task_alt,
            isLoading: state.isRunning(ClassesAction.complete),
            onPressed: enabled
                ? () => _run(
                    context,
                    () => editor.complete(session.id),
                    LocaleKeys.session_completed.tr(),
                  )
                : null,
          ),
        ],
        if (session.canRestore(now)) ...[
          const SizedBox(height: TelmizoSpacing.md),
          TelmizoSecondaryButton(
            key: const Key('session-restore'),
            label: LocaleKeys.session_restore_action.tr(),
            icon: Icons.restore,
            isLoading: state.isRunning(ClassesAction.restore),
            onPressed: enabled
                ? () => _run(
                    context,
                    () => editor.restore(session.id),
                    LocaleKeys.session_restored.tr(),
                  )
                : null,
          ),
        ],
        if (session.canCancel) ...[
          const SizedBox(height: TelmizoSpacing.md),
          TextButton.icon(
            key: const Key('session-cancel'),
            style: TextButton.styleFrom(
              foregroundColor: TelmizoColors.error,
              minimumSize: const Size.fromHeight(TelmizoSpacing.buttonHeight),
            ),
            onPressed: enabled
                ? () async {
                    if (!await confirmSessionCancel(context, session)) return;
                    if (!context.mounted) return;
                    await _run(
                      context,
                      () => editor.cancel(session.id),
                      LocaleKeys.session_cancelled.tr(),
                    );
                  }
                : null,
            icon: const Icon(Icons.cancel_outlined),
            label: Text(LocaleKeys.session_cancel_action.tr()),
          ),
        ],
        if (state.error case final error?) ...[
          const SizedBox(height: TelmizoSpacing.md),
          TelmizoInlineMessage(message: classesErrorMessage(error)),
        ],
      ],
    );
  }
}
