import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

class AllStudentsFilters extends StatelessWidget {
  const AllStudentsFilters({
    super.key,
    required this.searchController,
    required this.groups,
    required this.groupId,
    required this.status,
    required this.onSearchChanged,
    required this.onGroupChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final Map<String, String> groups;
  final String groupId;
  final MembershipStatus? status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onGroupChanged;
  final ValueChanged<MembershipStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final selectedGroup = groups.containsKey(groupId) ? groupId : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('all-students-search'),
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: LocaleKeys.all_students_search_hint.tr(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close),
                    tooltip: LocaleKeys.all_students_clear_search.tr(),
                  ),
          ),
        ),
        const SizedBox(height: TelmizoSpacing.md),
        DropdownButtonFormField<String>(
          key: ValueKey('all-students-group-filter-$selectedGroup'),
          initialValue: selectedGroup,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: LocaleKeys.all_students_group_filter.tr(),
          ),
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(LocaleKeys.all_students_all_groups.tr()),
            ),
            for (final entry in groups.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) => onGroupChanged(value ?? ''),
        ),
        const SizedBox(height: TelmizoSpacing.sm),
        Wrap(
          spacing: TelmizoSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(LocaleKeys.all_students_all_statuses.tr()),
              selected: status == null,
              onSelected: (_) => onStatusChanged(null),
            ),
            ChoiceChip(
              label: Text(LocaleKeys.access_status_active.tr()),
              selected: status == MembershipStatus.active,
              onSelected: (_) => onStatusChanged(MembershipStatus.active),
            ),
            ChoiceChip(
              label: Text(LocaleKeys.access_status_suspended.tr()),
              selected: status == MembershipStatus.suspended,
              onSelected: (_) => onStatusChanged(MembershipStatus.suspended),
            ),
          ],
        ),
      ],
    );
  }
}
