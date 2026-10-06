import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../domain/schedule_entry.dart';
import '../controllers/classes_editor_controller.dart';
import '../controllers/classes_providers.dart';
import '../formatting/session_formatting.dart';
import '../widgets/active_group_gate.dart';
import '../widgets/classes_empty_view.dart';
import '../widgets/schedule_entry_tile.dart';

/// The active weekly slots of one group.
@RoutePage()
class GroupScheduleScreen extends ConsumerWidget {
  const GroupScheduleScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    ScheduleEntry entry,
  ) async {
    if (!await confirmScheduleDeactivation(context)) return;
    final done = await ref
        .read(classesEditorControllerProvider.notifier)
        .deactivateSchedule(entry);
    if (done && context.mounted) {
      showTelmizoSnackBar(context, LocaleKeys.schedule_deactivated.tr());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(groupScheduleProvider(groupId));
    final editor = ref.watch(classesEditorControllerProvider);
    return Scaffold(
      appBar: AppHeader(title: LocaleKeys.schedule_title.tr(), showBack: true),
      body: ActiveGroupGate(
        groupId: groupId,
        builder: (group) => entries.when(
          skipLoadingOnRefresh: true,
          loading: () => const TelmizoLoadingView(),
          error: (error, _) => TelmizoErrorView(
            title: LocaleKeys.schedule_load_error_title.tr(),
            message: classesErrorMessage(error),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(groupScheduleProvider(groupId)),
          ),
          data: (entries) => RefreshIndicator(
            onRefresh: () => ref.refresh(groupScheduleProvider(groupId).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                TelmizoSpacing.margin,
                TelmizoSpacing.lg,
                TelmizoSpacing.margin,
                TelmizoSpacing.xl,
              ),
              children: [
                Text(group.name, style: context.textTheme.titleLarge),
                const SizedBox(height: TelmizoSpacing.md),
                TelmizoInlineMessage(
                  message: LocaleKeys.schedule_snapshot_notice.tr(),
                  tone: TelmizoMessageTone.info,
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                if (entries.isEmpty)
                  ClassesEmptyView(
                    icon: Icons.event_repeat,
                    title: LocaleKeys.schedule_empty_title.tr(),
                    body: LocaleKeys.schedule_empty_body.tr(),
                  ),
                for (final entry in entries) ...[
                  ScheduleEntryTile(
                    entry: entry,
                    enabled: !editor.isBusy,
                    onEdit: () => context.router.push(
                      EditScheduleEntryRoute(
                        groupId: groupId,
                        entryId: entry.id,
                      ),
                    ),
                    onDeactivate: () => _deactivate(context, ref, entry),
                  ),
                  const SizedBox(height: TelmizoSpacing.md),
                ],
                if (editor.error case final error?) ...[
                  TelmizoInlineMessage(message: classesErrorMessage(error)),
                  const SizedBox(height: TelmizoSpacing.md),
                ],
                const SizedBox(height: TelmizoSpacing.sm),
                TelmizoPrimaryButton(
                  key: const Key('add-weekly-schedule'),
                  label: LocaleKeys.schedule_add.tr(),
                  icon: Icons.add_circle_outline,
                  onPressed: () => context.router.push(
                    WeeklyScheduleFormRoute(groupId: groupId),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
