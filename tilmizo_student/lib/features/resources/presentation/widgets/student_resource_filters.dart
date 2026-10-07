import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../resource_labels.dart';

/// Category chips with live counts from the backend.
class StudentResourceFilters extends StatelessWidget {
  const StudentResourceFilters({
    super.key,
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  final Map<ResourceType, int> counts;
  final ResourceCategory? selected;
  final ValueChanged<ResourceCategory?> onChanged;

  int _count(ResourceCategory category) => counts.entries
      .where((entry) => category.contains(entry.key))
      .fold(0, (sum, entry) => sum + entry.value);

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (sum, count) => sum + count);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            key: const Key('student-resource-all'),
            label: LocaleKeys.resources_filter_all.tr(args: ['$total']),
            category: null,
          ),
          for (final category in ResourceCategory.values) ...[
            const SizedBox(width: TelmizoSpacing.sm),
            _chip(
              key: Key('student-resource-${category.name}'),
              label: category.label(_count(category)),
              category: category,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required Key key,
    required String label,
    required ResourceCategory? category,
  }) {
    final isSelected = selected == category;
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: isSelected,
      selectedColor: TelmizoColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? TelmizoColors.onPrimary : TelmizoColors.onSurface,
      ),
      checkmarkColor: TelmizoColors.onPrimary,
      onSelected: (_) => onChanged(category),
    );
  }
}
