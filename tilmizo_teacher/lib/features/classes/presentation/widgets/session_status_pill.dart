import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/class_session.dart';

/// The session's state as seen at [now].
class SessionStatusPill extends StatelessWidget {
  const SessionStatusPill({
    super.key,
    required this.session,
    required this.now,
  });

  final ClassSession session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final (label, icon, background, foreground) = switch (session.status) {
      SessionStatus.cancelled => (
        LocaleKeys.session_status_cancelled,
        Icons.event_busy_outlined,
        TelmizoColors.errorContainer,
        TelmizoColors.onErrorContainer,
      ),
      SessionStatus.completed => (
        LocaleKeys.session_status_completed,
        Icons.task_alt,
        TelmizoColors.successContainer,
        TelmizoColors.success,
      ),
      SessionStatus.scheduled when session.isInProgress(now) => (
        LocaleKeys.session_status_in_progress,
        Icons.circle,
        TelmizoColors.primaryTint,
        TelmizoColors.primary,
      ),
      SessionStatus.scheduled when !session.endsAt.isAfter(now) => (
        LocaleKeys.session_status_ended,
        Icons.history,
        TelmizoColors.surfaceContainerHigh,
        TelmizoColors.onSurfaceVariant,
      ),
      SessionStatus.scheduled => (
        LocaleKeys.session_status_scheduled,
        Icons.schedule,
        TelmizoColors.secondaryContainer,
        TelmizoColors.onSecondaryContainer,
      ),
    };
    return TelmizoPill(
      label: label.tr(),
      icon: icon,
      background: background,
      foreground: foreground,
    );
  }
}
