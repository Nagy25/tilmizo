import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../group_access/domain/student_access_state.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../controllers/student_resources_providers.dart';
import '../resource_labels.dart';
import 'student_resource_card.dart';
import 'student_resource_filters.dart';

/// The approved group's resources, read-only.
class StudentResourcesTab extends ConsumerStatefulWidget {
  const StudentResourcesTab({
    super.key,
    required this.groupId,
    required this.onRefresh,
  });

  final String groupId;

  /// Refreshes access and every tab of the group screen.
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<StudentResourcesTab> createState() =>
      _StudentResourcesTabState();
}

class _StudentResourcesTabState extends ConsumerState<StudentResourcesTab> {
  ResourceCategory? _category;
  final _failures = <String, ResourceFileFailureType>{};

  Future<void> _open(GroupResource resource) async {
    setState(() => _failures.remove(resource.id));
    final failure = await ref
        .read(resourceDownloadsProvider.notifier)
        .open(
          resource,
          authorize: () => confirmResourceAccess(ref, widget.groupId),
        );
    if (!mounted) return;
    if (failure != null) setState(() => _failures[resource.id] = failure);
    if (failure == ResourceFileFailureType.denied) {
      refreshStudentResources(ref, widget.groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Losing access stops downloads and deletes preview copies; the gated
    // providers drop the loaded list on their own.
    ref.listen(
      groupAccessOverviewProvider.select(
        (overview) => overview.whenData(
          (entries) =>
              findEntry(entries, widget.groupId)?.state ==
              StudentAccessState.approved,
        ),
      ),
      (_, next) {
        if (next case AsyncData(value: false)) {
          _failures.clear();
          ref.read(resourceDownloadsProvider.notifier).revokeAll();
        }
      },
    );
    final list = ref.watch(studentResourcesProvider(widget.groupId));
    final counts = ref.watch(studentResourceCountsProvider(widget.groupId));
    final sessions =
        ref.watch(studentResourceSessionsProvider(widget.groupId)).value ??
        const [];
    final labels = {
      for (final session in sessions)
        session.id: resourceSessionLabel(context, session),
    };
    final downloads = ref.watch(resourceDownloadsProvider);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TelmizoSpacing.margin,
          TelmizoSpacing.lg,
          TelmizoSpacing.margin,
          TelmizoSpacing.xl,
        ),
        children: [
          TelmizoInlineMessage(
            message: LocaleKeys.resources_intro.tr(),
            tone: TelmizoMessageTone.info,
          ),
          const SizedBox(height: TelmizoSpacing.md),
          StudentResourceFilters(
            counts: counts.value ?? const {},
            selected: _category,
            onChanged: (category) => setState(() => _category = category),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          ...switch (list) {
            AsyncData(:final value) => [
              ..._cards(value, labels, downloads),
              if (value.hasMore)
                TelmizoSecondaryButton(
                  key: const Key('student-resources-load-more'),
                  label: value.loadMoreFailed
                      ? LocaleKeys.resources_load_more_error.tr()
                      : LocaleKeys.resources_load_more.tr(),
                  isLoading: value.isLoadingMore,
                  onPressed: value.isLoadingMore
                      ? null
                      : () => ref
                            .read(
                              studentResourcesProvider(widget.groupId).notifier,
                            )
                            .loadMore(),
                ),
            ],
            AsyncError(:final error) => [_errorView(error)],
            _ => [
              const Padding(
                padding: EdgeInsets.all(TelmizoSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }

  List<Widget> _cards(
    StudentResourcesState state,
    Map<String, String> labels,
    ResourceDownloads downloads,
  ) {
    if (state.resources.isEmpty) {
      return [
        _Message(
          key: const Key('student-resources-empty'),
          icon: Icons.folder_open_outlined,
          title: LocaleKeys.resources_empty_title.tr(),
          body: LocaleKeys.resources_empty_body.tr(),
        ),
      ];
    }
    final visible = [
      for (final resource in state.resources)
        if (_category?.contains(resource.type) ?? true) resource,
    ];
    if (visible.isEmpty) {
      return [
        _Message(
          icon: Icons.filter_alt_off_outlined,
          title: LocaleKeys.resources_no_matches.tr(),
        ),
      ];
    }
    return [
      for (final resource in visible) ...[
        StudentResourceCard(
          resource: resource,
          sessionLabel: labels[resource.sessionId],
          downloadProgress: downloads[resource.id],
          failure: _failures[resource.id],
          onOpen: () => _open(resource),
          onCancel: () =>
              ref.read(resourceDownloadsProvider.notifier).cancel(resource.id),
        ),
        const SizedBox(height: TelmizoSpacing.md),
      ],
    ];
  }

  Widget _errorView(Object error) {
    final type = failureTypeOf(error);
    final accessLost = type == AppFailureType.notFound;
    return _Message(
      key: const Key('student-resources-error'),
      icon: accessLost ? Icons.lock_outline : Icons.cloud_off_outlined,
      title: accessLost
          ? LocaleKeys.resources_access_lost_title.tr()
          : LocaleKeys.resources_load_error_title.tr(),
      body: accessLost
          ? LocaleKeys.resources_access_lost_body.tr()
          : appFailureMessage(type),
      actionLabel: LocaleKeys.common_retry.tr(),
      onAction: () => refreshStudentResources(ref, widget.groupId),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => TelmizoCard(
    child: Column(
      children: [
        Icon(icon, size: 40, color: TelmizoColors.onSurfaceVariant),
        const SizedBox(height: TelmizoSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium,
        ),
        if (body case final body?) ...[
          const SizedBox(height: TelmizoSpacing.xs),
          Text(body, textAlign: TextAlign.center),
        ],
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}
