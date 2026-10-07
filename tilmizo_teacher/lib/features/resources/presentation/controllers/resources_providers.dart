import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/controllers/resource_storage_usage_controller.dart';
import '../../data/resources_repository_impl.dart';
import '../../domain/resource_models.dart';
import '../../domain/resources_repository.dart';

@immutable
final class ResourcesListState {
  const ResourcesListState({
    required this.resources,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  final List<GroupResource> resources;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? loadMoreFailure;
}

/// A group's resources, newest first, paged by offset.
final resourcesListProvider = AsyncNotifierProvider.autoDispose
    .family<ResourcesListController, ResourcesListState, String>(
      ResourcesListController.new,
    );

class ResourcesListController extends AsyncNotifier<ResourcesListState> {
  ResourcesListController(this.groupId);

  static const pageSize = 30;

  final String groupId;

  ResourcesRepository get _repository => ref.read(resourcesRepositoryProvider);

  @override
  Future<ResourcesListState> build() async {
    final page = await ref
        .watch(resourcesRepositoryProvider)
        .fetchResources(groupId, limit: pageSize);
    return ResourcesListState(resources: page.resources, hasMore: page.hasMore);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    ref.invalidate(resourceTypeCountsProvider(groupId));
    await future;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      ResourcesListState(
        resources: current.resources,
        hasMore: true,
        isLoadingMore: true,
      ),
    );
    try {
      final page = await _repository.fetchResources(
        groupId,
        offset: current.resources.length,
        limit: pageSize,
      );
      if (!ref.mounted) return;
      final known = {for (final resource in current.resources) resource.id};
      state = AsyncData(
        ResourcesListState(
          resources: [
            ...current.resources,
            ...page.resources.where((r) => !known.contains(r.id)),
          ],
          hasMore: page.hasMore,
        ),
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = AsyncData(
        ResourcesListState(
          resources: current.resources,
          hasMore: true,
          loadMoreFailure: error,
        ),
      );
    }
  }

  /// Deletes through `resource-delete`. Both `200` and `202` mean the
  /// resource is gone, so the card is removed either way.
  Future<ResourceDeletion> delete(String resourceId) async {
    final deletion = await _repository.deleteResource(resourceId);
    if (!ref.mounted) return deletion;
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        ResourcesListState(
          resources: [
            for (final resource in current.resources)
              if (resource.id != resourceId) resource,
          ],
          hasMore: current.hasMore,
        ),
      );
    }
    ref.invalidate(resourceTypeCountsProvider(groupId));
    ref.invalidate(resourceDetailsProvider(resourceId));
    refreshStorageUsage(ref, cleanupPending: deletion.cleanupPending);
    return deletion;
  }
}

final resourceTypeCountsProvider = FutureProvider.autoDispose
    .family<Map<ResourceType, int>, String>(
      (ref, groupId) =>
          ref.watch(resourcesRepositoryProvider).fetchTypeCounts(groupId),
    );

final resourceSessionsProvider = FutureProvider.autoDispose
    .family<List<ResourceSessionOption>, String>(
      (ref, groupId) =>
          ref.watch(resourcesRepositoryProvider).fetchSessions(groupId),
    );

final resourceDetailsProvider = FutureProvider.autoDispose
    .family<GroupResource, String>((ref, resourceId) async {
      final resource = await ref
          .watch(resourcesRepositoryProvider)
          .fetchResource(resourceId);
      if (resource == null) throw const AppFailure(AppFailureType.notFound);
      return resource;
    });

/// Reloads a group's resource views after a create or edit.
void refreshResourceViews(Ref ref, String groupId, {String? resourceId}) {
  ref.invalidate(resourcesListProvider(groupId));
  ref.invalidate(resourceTypeCountsProvider(groupId));
  if (resourceId != null) ref.invalidate(resourceDetailsProvider(resourceId));
  refreshStorageUsage(ref);
}

/// Delay before re-reading quota while deferred object cleanup runs.
const storageCleanupRefreshDelay = Duration(seconds: 30);

/// Refreshes the teacher-wide quota now and, when object cleanup is still
/// pending, once more after [storageCleanupRefreshDelay].
void refreshStorageUsage(Ref ref, {bool cleanupPending = false}) {
  ref.invalidate(resourceStorageUsageProvider);
  if (!cleanupPending) return;
  final container = ref.container;
  Timer(storageCleanupRefreshDelay, () {
    try {
      container.invalidate(resourceStorageUsageProvider);
    } on StateError {
      // The container was disposed; nothing to refresh.
    }
  });
}
