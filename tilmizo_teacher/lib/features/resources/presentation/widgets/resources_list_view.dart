import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../groups/domain/teacher_group.dart';
import '../../../profile/presentation/controllers/resource_storage_usage_controller.dart';
import '../../domain/resource_filters.dart';
import '../controllers/resources_providers.dart';
import '../resource_labels.dart';
import 'delete_resource_dialog.dart';
import 'resource_card.dart';
import 'resource_filters_bar.dart';
import 'resources_list_states.dart';
import 'teacher_storage_card.dart';

/// The group's resources with teacher-wide quota, filters and actions.
class ResourcesListView extends ConsumerStatefulWidget {
  const ResourcesListView({
    super.key,
    required this.group,
    required this.onAdd,
  });

  final TeacherGroup group;
  final VoidCallback onAdd;

  @override
  ConsumerState<ResourcesListView> createState() => _ResourcesListViewState();
}

class _ResourcesListViewState extends ConsumerState<ResourcesListView> {
  final _search = TextEditingController();
  var _filters = const ResourceFilters();

  String get _groupId => widget.group.id;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(resourceStorageUsageProvider);
    ref.invalidate(resourceSessionsProvider(_groupId));
    await ref.read(resourcesListProvider(_groupId).notifier).refresh();
  }

  void _clearFilters() {
    _search.clear();
    setState(() => _filters = const ResourceFilters());
  }

  Future<void> _open(GroupResource resource) async {
    final failure = await ref
        .read(resourceDownloadsProvider.notifier)
        .open(resource);
    if (failure == null || !mounted) return;
    showTelmizoSnackBar(context, resourceOpenFailureMessage(failure));
    if (failure == ResourceFileFailureType.denied) await _refresh();
  }

  Future<void> _onAction(
    GroupResource resource,
    ResourceCardAction action,
    String? sessionLabel,
  ) async {
    switch (action) {
      case ResourceCardAction.edit:
        await context.router.push(
          EditResourceRoute(groupId: _groupId, resourceId: resource.id),
        );
      case ResourceCardAction.delete:
        await _delete(resource, sessionLabel);
    }
  }

  Future<void> _delete(GroupResource resource, String? sessionLabel) async {
    final confirmed = await confirmResourceDelete(
      context,
      resource,
      sessionLabel: sessionLabel,
    );
    if (!confirmed || !mounted) return;
    try {
      final deletion = await ref
          .read(resourcesListProvider(_groupId).notifier)
          .delete(resource.id);
      unawaited(
        ref.read(resourceDownloadsProvider.notifier).evict(resource.id),
      );
      if (!mounted) return;
      showTelmizoSnackBar(
        context,
        deletion.cleanupPending
            ? LocaleKeys.resource_delete_cleanup_pending.tr()
            : LocaleKeys.resource_delete_success.tr(),
      );
    } catch (error) {
      if (mounted) showTelmizoSnackBar(context, resourceFailureMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(resourcesListProvider(_groupId));
    final counts = ref.watch(resourceTypeCountsProvider(_groupId)).value;
    final sessions =
        ref.watch(resourceSessionsProvider(_groupId)).value ?? const [];
    final downloads = ref.watch(resourceDownloadsProvider);
    final sessionLabels = {
      for (final session in sessions)
        session.id: context.resourceSessionLabel(session),
    };
    final canManage = widget.group.isActive;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          TelmizoSpacing.md,
          TelmizoSpacing.margin,
          TelmizoSpacing.xxl * 2,
        ),
        children: [
          const TeacherStorageCard(),
          if (!canManage) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(
              message: LocaleKeys.resources_archived_notice.tr(),
              tone: TelmizoMessageTone.info,
            ),
          ],
          const SizedBox(height: TelmizoSpacing.lg),
          ResourceFiltersBar(
            filters: _filters,
            searchController: _search,
            categoryCounts: categoryCounts(counts ?? const {}),
            sessions: sessions,
            onChanged: (filters) => setState(() => _filters = filters),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          ...switch (list) {
            AsyncData(:final value) => _content(
              value,
              sessionLabels,
              downloads,
              canManage,
            ),
            AsyncError(:final error) => [
              ResourcesLoadError(
                error: error,
                onRetry: () => ref.invalidate(resourcesListProvider(_groupId)),
              ),
            ],
            _ => [const ResourcesLoading()],
          },
        ],
      ),
    );
  }

  List<Widget> _content(
    ResourcesListState state,
    Map<String, String> sessionLabels,
    ResourceDownloads downloads,
    bool canManage,
  ) {
    if (state.resources.isEmpty) {
      return [ResourcesEmptyView(canAdd: canManage, onAdd: widget.onAdd)];
    }
    final visible = _filters.apply(state.resources);
    return [
      if (visible.isEmpty)
        ResourcesNoMatches(onClear: _clearFilters)
      else
        for (final resource in visible) ...[
          ResourceCard(
            resource: resource,
            sessionLabel: sessionLabels[resource.sessionId],
            canManage: canManage,
            downloadProgress: downloads[resource.id],
            onOpen: () => _open(resource),
            onCancelDownload: () => ref
                .read(resourceDownloadsProvider.notifier)
                .cancel(resource.id),
            onAction: (action) =>
                _onAction(resource, action, sessionLabels[resource.sessionId]),
          ),
          const SizedBox(height: TelmizoSpacing.md),
        ],
      if (state.hasMore)
        ResourcesLoadMore(
          isLoading: state.isLoadingMore,
          failed: state.loadMoreFailure != null,
          onPressed: () =>
              ref.read(resourcesListProvider(_groupId).notifier).loadMore(),
        ),
    ];
  }
}
