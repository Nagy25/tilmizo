import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

enum SessionEditMode { reschedule, location, cancel }

/// Radio cards choosing what to change about one session.
class EditModeSelector extends StatelessWidget {
  const EditModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final SessionEditMode selected;
  final ValueChanged<SessionEditMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => RadioGroup<SessionEditMode>(
    groupValue: selected,
    onChanged: (mode) {
      if (enabled && mode != null) onChanged(mode);
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final mode in SessionEditMode.values) ...[
          _ModeCard(mode: mode, selected: mode == selected, enabled: enabled),
          const SizedBox(height: TelmizoSpacing.sm),
        ],
      ],
    ),
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.enabled,
  });

  final SessionEditMode mode;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isCancel = mode == SessionEditMode.cancel;
    final (title, body, icon) = switch (mode) {
      SessionEditMode.reschedule => (
        LocaleKeys.session_edit_reschedule,
        LocaleKeys.session_edit_reschedule_body,
        Icons.event_repeat,
      ),
      SessionEditMode.location => (
        LocaleKeys.session_edit_location,
        LocaleKeys.session_edit_location_body,
        Icons.videocam_outlined,
      ),
      SessionEditMode.cancel => (
        LocaleKeys.session_edit_cancel,
        LocaleKeys.session_edit_cancel_body,
        Icons.event_busy_outlined,
      ),
    };
    final accent = isCancel ? TelmizoColors.error : TelmizoColors.primary;
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.06)
          : TelmizoColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: TelmizoRadius.lgAll,
        side: BorderSide(
          color: selected ? accent : TelmizoColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: RadioListTile<SessionEditMode>(
        key: Key('edit-mode-${mode.name}'),
        value: mode,
        enabled: enabled,
        activeColor: accent,
        shape: const RoundedRectangleBorder(borderRadius: TelmizoRadius.lgAll),
        secondary: Icon(icon, color: accent),
        title: Text(title.tr()),
        subtitle: Text(body.tr()),
      ),
    );
  }
}
