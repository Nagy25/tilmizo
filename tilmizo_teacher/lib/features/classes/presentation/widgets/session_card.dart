import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/class_session.dart';
import '../formatting/session_formatting.dart';
import 'session_location_line.dart';
import 'session_status_pill.dart';

/// A session summary: group, subject, Cairo date and time, and location.
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.now,
    required this.onTap,
    this.onAttendance,
  });

  final ClassSession session;
  final DateTime now;
  final VoidCallback onTap;

  /// Shown only when attendance can be taken for the session.
  final VoidCallback? onAttendance;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final relative = session.isCancelled
        ? null
        : context.relativeDay(session.startsAt, now);
    final subject = session.group.subject;
    return TelmizoCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('session-card-${session.id}'),
          borderRadius: TelmizoRadius.xlAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(TelmizoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: TelmizoSpacing.sm,
                  runSpacing: TelmizoSpacing.xs,
                  children: [
                    SessionStatusPill(session: session, now: now),
                    if (relative != null && session.isUpcoming(now))
                      TelmizoPill(
                        label: relative,
                        background: TelmizoColors.surfaceContainerLow,
                        foreground: TelmizoColors.onSurface,
                      ),
                  ],
                ),
                const SizedBox(height: TelmizoSpacing.sm),
                Text(session.group.name, style: textTheme.titleMedium),
                if (subject != null)
                  Text(
                    subject,
                    style: textTheme.bodySmall?.copyWith(
                      color: TelmizoColors.secondary,
                    ),
                  ),
                const SizedBox(height: TelmizoSpacing.md),
                Container(
                  padding: const EdgeInsets.all(TelmizoSpacing.md),
                  decoration: const BoxDecoration(
                    color: TelmizoColors.surfaceContainerLow,
                    borderRadius: TelmizoRadius.lgAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: TelmizoColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: TelmizoSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.cairoDate(session.startsAt),
                                  style: textTheme.bodyMedium,
                                ),
                                Text(
                                  context.sessionTimeRange(session),
                                  style: textTheme.titleSmall?.copyWith(
                                    color: TelmizoColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TelmizoSpacing.sm),
                      SessionLocationLine(location: session.location),
                    ],
                  ),
                ),
                if (onAttendance != null) ...[
                  const SizedBox(height: TelmizoSpacing.md),
                  FilledButton.icon(
                    onPressed: onAttendance,
                    icon: const Icon(Icons.how_to_reg_outlined),
                    label: Text(LocaleKeys.session_take_attendance.tr()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
