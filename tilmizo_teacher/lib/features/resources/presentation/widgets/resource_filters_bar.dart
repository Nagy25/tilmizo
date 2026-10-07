import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/resource_filters.dart';
import '../resource_labels.dart';

/// Search, type-category chips with live counts, and a session filter.
class ResourceFiltersBar extends StatelessWidget {
  const ResourceFiltersBar({
    super.key,
    required this.filters,
    required this.searchController,
    required this.categoryCounts,
    required this.sessions,
    required this.onChanged,
  });

  final ResourceFilters filters;
  final TextEditingController searchController;
  final Map<ResourceCategory, int> categoryCounts;

  /// Sessions in the group; the session filter is hidden when empty.
  final List<ResourceSessionOption> sessions;
  final ValueChanged<ResourceFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final total = categoryCounts.values.fold(0, (sum, count) => sum + count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('resources-search'),
          controller: searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => onChanged(filters.copyWith(query: value)),
          decoration: InputDecoration(
            hintText: LocaleKeys.resources_search_hint.tr(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: filters.query.isEmpty
                ? null
                : IconButton(
                    tooltip: LocaleKeys.resources_search_clear.tr(),
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      onChanged(filters.copyWith(query: ''));
                    },
                  ),
          ),
        ),
        const SizedBox(height: TelmizoSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(
                key: const Key('resource-category-all'),
                label: LocaleKeys.resources_filter_all.tr(args: ['$total']),
                selected: filters.category == null,
                onSelected: () =>
                    onChanged(filters.copyWith(category: () => null)),
              ),
              for (final category in ResourceCategory.values) ...[
                const SizedBox(width: TelmizoSpacing.sm),
                _chip(
                  key: Key('resource-category-${category.name}'),
                  label: category.label(categoryCounts[category] ?? 0),
                  selected: filters.category == category,
                  onSelected: () =>
                      onChanged(filters.copyWith(category: () => category)),
                ),
              ],
            ],
          ),
        ),
        if (sessions.isNotEmpty) ...[
          const SizedBox(height: TelmizoSpacing.sm),
          DropdownButtonFormField<String?>(
            key: const Key('resources-session-filter'),
            initialValue: filters.sessionId,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.event_note_outlined),
            ),
            items: [
              DropdownMenuItem(
                child: Text(LocaleKeys.resources_session_filter_all.tr()),
              ),
              for (final session in sessions)
                DropdownMenuItem(
                  value: session.id,
                  child: Text(
                    context.resourceSessionLabel(session),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) => onChanged(filters.copyWith(sessionId: () => id)),
          ),
        ],
      ],
    );
  }

  Widget _chip({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) => ChoiceChip(
    key: key,
    label: Text(label),
    selected: selected,
    selectedColor: TelmizoColors.secondary,
    labelStyle: TextStyle(
      color: selected ? TelmizoColors.onSecondary : TelmizoColors.onSurface,
    ),
    checkmarkColor: TelmizoColors.onSecondary,
    onSelected: (_) => onSelected(),
  );
}
