import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/schedule_entry.dart';
import '../controllers/classes_editor_controller.dart';
import '../controllers/classes_providers.dart';
import '../formatting/session_formatting.dart';
import '../widgets/active_group_gate.dart';
import '../widgets/weekly_day_card.dart';

/// Edits one weekly slot. Only sessions generated afterwards use the change.
@RoutePage()
class EditScheduleEntryScreen extends ConsumerWidget {
  const EditScheduleEntryScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
    @PathParam('entryId') required this.entryId,
  });

  final String groupId;
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(scheduleEntryProvider(entryId));
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.schedule_form_edit_title.tr(),
        showBack: true,
      ),
      body: ActiveGroupGate(
        groupId: groupId,
        builder: (_) => entry.when(
          loading: () => const TelmizoLoadingView(),
          error: (error, _) => TelmizoErrorView(
            title: LocaleKeys.schedule_load_error_title.tr(),
            message: classesErrorMessage(error),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(scheduleEntryProvider(entryId)),
          ),
          data: (entry) => entry.isActive && entry.groupId == groupId
              ? _EntryForm(key: ValueKey(entry), entry: entry)
              : TelmizoErrorView(
                  icon: Icons.lock_outline,
                  title: LocaleKeys.schedule_form_edit_title.tr(),
                  message: LocaleKeys.schedule_entry_inactive.tr(),
                  retryLabel: LocaleKeys.common_back.tr(),
                  onRetry: () => context.router.maybePop(),
                ),
        ),
      ),
    );
  }
}

class _EntryForm extends ConsumerStatefulWidget {
  const _EntryForm({super.key, required this.entry});

  final ScheduleEntry entry;

  @override
  ConsumerState<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<_EntryForm> {
  final _formKey = GlobalKey<FormState>();
  late final _draft = WeeklyDayDraft(
    widget.entry.slot.weekday,
    from: widget.entry.slot,
  );

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final slot = _draft.toSlot();
    if (slot == null) return;
    if (slot == widget.entry.slot) {
      showTelmizoSnackBar(context, LocaleKeys.session_no_changes.tr());
      return;
    }
    final updated = await ref
        .read(classesEditorControllerProvider.notifier)
        .updateSchedule(widget.entry, slot);
    if (updated == null || !mounted) return;
    showTelmizoSnackBar(context, LocaleKeys.session_updated.tr());
    await context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classesEditorControllerProvider);
    final error = state.error;
    return Form(
      key: _formKey,
      child: TelmizoScrollBody(
        children: [
          TelmizoInlineMessage(
            message: LocaleKeys.schedule_edit_notice.tr(),
            tone: TelmizoMessageTone.warning,
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          WeeklyDayCard(
            draft: _draft,
            enabled: !state.isBusy,
            onChanged: () => setState(() {}),
          ),
          if (error != null) ...[
            const SizedBox(height: TelmizoSpacing.lg),
            TelmizoInlineMessage(message: classesErrorMessage(error)),
          ],
          const SizedBox(height: TelmizoSpacing.xl),
          TelmizoPrimaryButton(
            key: const Key('save-schedule-entry'),
            label: LocaleKeys.schedule_save_edit.tr(),
            icon: Icons.save_outlined,
            isLoading: state.isRunning(ClassesAction.updateSchedule),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
