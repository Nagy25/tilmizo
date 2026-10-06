import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../domain/classes_repository.dart';

/// Upcoming, past, and cancelled session views.
class SessionsViewTabs extends StatelessWidget {
  const SessionsViewTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SessionsView selected;
  final ValueChanged<SessionsView> onChanged;

  @override
  Widget build(BuildContext context) => _ChipRow(
    children: [
      for (final view in SessionsView.values)
        ChoiceChip(
          key: Key('sessions-view-${view.name}'),
          label: Text(switch (view) {
            SessionsView.upcoming => LocaleKeys.classes_tab_upcoming.tr(),
            SessionsView.past => LocaleKeys.classes_tab_past.tr(),
            SessionsView.cancelled => LocaleKeys.classes_tab_cancelled.tr(),
          }),
          selected: view == selected,
          selectedColor: TelmizoColors.secondary,
          labelStyle: TextStyle(
            color: view == selected
                ? TelmizoColors.onSecondary
                : TelmizoColors.onSurface,
          ),
          checkmarkColor: TelmizoColors.onSecondary,
          onSelected: (_) => onChanged(view),
        ),
    ],
  );
}

/// All-groups or single-group filter for the teacher-wide classes list.
class GroupFilterChips extends StatelessWidget {
  const GroupFilterChips({
    super.key,
    required this.groups,
    required this.selectedId,
    required this.onChanged,
  });

  final List<TeacherGroup> groups;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => _ChipRow(
    children: [
      FilterChip(
        label: Text(LocaleKeys.classes_all_groups.tr()),
        selected: selectedId == null,
        onSelected: (_) => onChanged(null),
      ),
      for (final group in groups)
        FilterChip(
          key: Key('group-filter-${group.id}'),
          label: Text(group.name),
          selected: selectedId == group.id,
          onSelected: (_) => onChanged(group.id),
        ),
    ],
  );
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (index, chip) in children.indexed) ...[
          if (index > 0) const SizedBox(width: TelmizoSpacing.sm),
          chip,
        ],
      ],
    ),
  );
}
