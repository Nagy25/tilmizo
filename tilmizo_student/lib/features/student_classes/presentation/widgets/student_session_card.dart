import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/student_class.dart';
import '../formatting/student_class_formatting.dart';

class StudentSessionCard extends StatelessWidget {
  const StudentSessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.showAttendance = false,
  });

  final StudentClassSession session;
  final VoidCallback onTap;
  final bool showAttendance;

  @override
  Widget build(BuildContext context) {
    final location = session.locationType == SessionLocationType.physical
        ? session.physicalLocation
        : LocaleKeys.session_online.tr();
    final subject = session.subject;
    return Padding(
      padding: const EdgeInsets.only(bottom: TelmizoSpacing.md),
      child: TelmizoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: TelmizoSpacing.sm,
              runSpacing: TelmizoSpacing.xs,
              children: [
                TelmizoPill(
                  label: sessionStatusLabel(session.status),
                  background: session.status == SessionStatus.cancelled
                      ? TelmizoColors.errorContainer
                      : TelmizoColors.primaryTint,
                  foreground: session.status == SessionStatus.cancelled
                      ? TelmizoColors.error
                      : TelmizoColors.primary,
                ),
                if (showAttendance && session.status != SessionStatus.cancelled)
                  TelmizoPill(
                    label: attendanceLabel(session.attendance),
                    background: TelmizoColors.surfaceContainerLow,
                    foreground: TelmizoColors.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: TelmizoSpacing.sm),
            Text(session.groupName, style: context.textTheme.titleMedium),
            if (subject != null && subject.isNotEmpty)
              Text(subject, style: context.textTheme.bodySmall),
            const SizedBox(height: TelmizoSpacing.sm),
            _Line(
              icon: Icons.calendar_today_outlined,
              text: sessionDate(context, session.startsAt),
            ),
            _Line(
              icon: Icons.schedule_outlined,
              text: sessionTimeRange(context, session.startsAt, session.endsAt),
            ),
            if (location != null && location.isNotEmpty)
              _Line(
                icon: session.locationType == SessionLocationType.online
                    ? Icons.videocam_outlined
                    : Icons.location_on_outlined,
                text: location,
              ),
            if (session.status == SessionStatus.cancelled) ...[
              const SizedBox(height: TelmizoSpacing.sm),
              Text(
                LocaleKeys.session_cancelled_warning.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: TelmizoColors.error,
                ),
              ),
            ],
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward),
                label: Text(LocaleKeys.session_details_action.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: TelmizoSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 18, color: TelmizoColors.onSurfaceVariant),
        const SizedBox(width: TelmizoSpacing.sm),
        Expanded(child: Text(text, style: context.textTheme.bodySmall)),
      ],
    ),
  );
}
