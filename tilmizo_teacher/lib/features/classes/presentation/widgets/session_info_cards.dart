import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/class_session.dart';
import '../formatting/session_formatting.dart';
import 'session_location_line.dart';
import 'session_status_pill.dart';

/// Group, subject, status, and origin of a session.
class SessionHeaderCard extends StatelessWidget {
  const SessionHeaderCard({
    super.key,
    required this.session,
    required this.now,
  });

  final ClassSession session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final relative = session.isUpcoming(now)
        ? context.relativeDay(session.startsAt, now)
        : null;
    return TelmizoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: TelmizoSpacing.sm,
            runSpacing: TelmizoSpacing.xs,
            children: [
              SessionStatusPill(session: session, now: now),
              if (relative != null)
                TelmizoPill(
                  label: relative,
                  background: TelmizoColors.surfaceContainerLow,
                  foreground: TelmizoColors.onSurface,
                ),
              TelmizoPill(
                label:
                    (session.isRecurring
                            ? LocaleKeys.session_recurring
                            : LocaleKeys.session_one_time)
                        .tr(),
                icon: session.isRecurring ? Icons.event_repeat : Icons.bolt,
                background: TelmizoColors.secondaryContainer,
                foreground: TelmizoColors.onSecondaryContainer,
              ),
            ],
          ),
          const SizedBox(height: TelmizoSpacing.md),
          Text(session.group.name, style: textTheme.headlineSmall),
          if (session.group.subject case final subject?)
            Text(
              subject,
              style: textTheme.bodyMedium?.copyWith(
                color: TelmizoColors.secondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Cairo date, time range, and duration.
class SessionWhenCard extends StatelessWidget {
  const SessionWhenCard({super.key, required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.calendar_month_outlined,
    title: LocaleKeys.session_when_title.tr(),
    children: [
      _Row(
        label: LocaleKeys.session_date_row.tr(),
        value: context.cairoDate(session.startsAt),
      ),
      _Row(
        label: LocaleKeys.session_time_row.tr(),
        value: context.sessionTimeRange(session),
      ),
      _Row(
        label: LocaleKeys.session_duration_row.tr(),
        value: context.durationLabel(session.duration),
      ),
      const SizedBox(height: TelmizoSpacing.sm),
      Row(
        children: [
          const Icon(Icons.public, size: 16, color: TelmizoColors.outline),
          const SizedBox(width: TelmizoSpacing.xs),
          Text(
            LocaleKeys.session_cairo_time.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Address or meeting link with copy and share actions.
class SessionLocationCard extends StatelessWidget {
  const SessionLocationCard({super.key, required this.session});

  final ClassSession session;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: session.location.value));
    if (context.mounted) {
      showTelmizoSnackBar(context, LocaleKeys.session_copied.tr());
    }
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: session.location.value,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _SectionCard(
    icon: Icons.place_outlined,
    title: LocaleKeys.session_location_title.tr(),
    children: [
      SessionLocationLine(location: session.location),
      const SizedBox(height: TelmizoSpacing.md),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.content_copy, size: 18),
              label: Text(LocaleKeys.session_copy.tr()),
            ),
          ),
          const SizedBox(width: TelmizoSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: Text(LocaleKeys.session_share.tr()),
            ),
          ),
        ],
      ),
    ],
  );
}

/// The class note shared by the whole session.
class SessionNotesCard extends StatelessWidget {
  const SessionNotesCard({super.key, required this.session, this.onEdit});

  final ClassSession session;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final notes = session.notes;
    return _SectionCard(
      icon: Icons.edit_note,
      title: LocaleKeys.session_notes_title.tr(),
      trailing: onEdit == null
          ? null
          : IconButton(
              key: const Key('edit-session-notes'),
              onPressed: onEdit,
              tooltip: LocaleKeys.session_notes_edit.tr(),
              icon: const Icon(Icons.edit_outlined),
            ),
      children: [
        Text(
          notes ?? LocaleKeys.session_notes_empty.tr(),
          style: context.textTheme.bodyMedium?.copyWith(
            color: notes == null ? TelmizoColors.onSurfaceVariant : null,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: TelmizoColors.primaryTint,
              foregroundColor: TelmizoColors.primary,
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: TelmizoSpacing.sm),
            Expanded(child: Text(title, style: context.textTheme.titleMedium)),
            ?trailing,
          ],
        ),
        const SizedBox(height: TelmizoSpacing.md),
        ...children,
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TelmizoSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: context.textTheme.bodyMedium)),
      ],
    ),
  );
}
