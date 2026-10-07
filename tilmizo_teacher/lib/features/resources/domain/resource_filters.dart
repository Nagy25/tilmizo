import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';

/// Client-side list filters, as the backend contract prescribes.
@immutable
final class ResourceFilters {
  const ResourceFilters({this.query = '', this.category, this.sessionId});

  final String query;
  final ResourceCategory? category;
  final String? sessionId;

  bool get isActive =>
      query.trim().isNotEmpty || category != null || sessionId != null;

  ResourceFilters copyWith({
    String? query,
    ValueGetter<ResourceCategory?>? category,
    ValueGetter<String?>? sessionId,
  }) => ResourceFilters(
    query: query ?? this.query,
    category: category == null ? this.category : category(),
    sessionId: sessionId == null ? this.sessionId : sessionId(),
  );

  List<GroupResource> apply(List<GroupResource> resources) {
    final needle = query.trim().toLowerCase();
    return [
      for (final resource in resources)
        if ((category?.contains(resource.type) ?? true) &&
            (sessionId == null || resource.sessionId == sessionId) &&
            (needle.isEmpty || _matches(resource, needle)))
          resource,
    ];
  }

  static bool _matches(GroupResource resource, String needle) => [
    resource.title,
    resource.description,
    resource.fileName,
    resource.linkHost,
  ].any((value) => value?.toLowerCase().contains(needle) ?? false);
}

/// Totals per category from per-type counts.
Map<ResourceCategory, int> categoryCounts(Map<ResourceType, int> typeCounts) =>
    {
      for (final category in ResourceCategory.values)
        category: typeCounts.entries
            .where((entry) => category.contains(entry.key))
            .fold(0, (sum, entry) => sum + entry.value),
    };
