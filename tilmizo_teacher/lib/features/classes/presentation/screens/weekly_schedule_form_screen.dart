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
import '../widgets/weekday_chips.dart';
import '../widgets/weekly_day_card.dart';

/// Creates recurring weekly slots, each weekday with its own times and
/// location. All slots are saved together or not at all.
@RoutePage()
class WeeklyScheduleFormScreen extends ConsumerStatefulWidget {
  const WeeklyScheduleFormScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  ConsumerState<WeeklyScheduleFormScreen> createState() =>
      _WeeklyScheduleFormScreenState();
}

class _WeeklyScheduleFormScreenState
    extends ConsumerState<WeeklyScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _days = <int, WeeklyDayDraft>{};
  bool _showDaysError = false;
  bool _showConflict = false;

  @override
  void dispose() {
    for (final day in _days.values) {
      day.dispose();
    }
    super.dispose();
  }

  void _toggle(int weekday) => setState(() {
    _showDaysError = false;
    final removed = _days.remove(weekday);
    if (removed != null) {
      removed.dispose();
    } else {
      _days[weekday] = WeeklyDayDraft(weekday);
    }
  });

  Future<void> _submit() async {
    setState(() {
      _showDaysError = _days.isEmpty;
      _showConflict = false;
    });
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _days.isEmpty) return;
    final slots = [
      for (final weekday in weekdayDisplayOrder) ?_days[weekday]?.toSlot(),
    ];
    if (slots.length != _days.length) return;

    final existing = ref.read(groupScheduleProvider(widget.groupId)).value;
    if (existing != null &&
        slots.any((s) => existing.any((e) => e.slot.sameTimeAs(s)))) {
      setState(() => _showConflict = true);
      return;
    }

    final saved = await ref
        .read(classesEditorControllerProvider.notifier)
        .createSchedule(widget.groupId, slots);
    if (!saved || !mounted) return;
    showTelmizoSnackBar(context, LocaleKeys.schedule_saved.tr());
    await context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Loads existing slots so duplicates are caught before saving.
    ref.watch(groupScheduleProvider(widget.groupId));
    final state = ref.watch(classesEditorControllerProvider);
    final error = _showConflict ? const ScheduleConflict() : state.error;
    final ordered = [
      for (final weekday in weekdayDisplayOrder) ?_days[weekday],
    ];

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.schedule_form_title.tr(),
        showBack: true,
      ),
      body: ActiveGroupGate(
        blockSuspended: true,
        groupId: widget.groupId,
        builder: (group) => Form(
          key: _formKey,
          child: TelmizoScrollBody(
            children: [
              Text(group.name, style: context.textTheme.titleLarge),
              const SizedBox(height: TelmizoSpacing.md),
              TelmizoInlineMessage(
                title: LocaleKeys.schedule_form_banner_title.tr(),
                message: LocaleKeys.schedule_form_banner.tr(),
                tone: TelmizoMessageTone.info,
              ),
              const SizedBox(height: TelmizoSpacing.lg),
              WeekdayChips(
                selected: _days.keys.toSet(),
                enabled: !state.isBusy,
                onToggled: _toggle,
                errorText: _showDaysError
                    ? LocaleKeys.schedule_days_required.tr()
                    : null,
              ),
              for (final day in ordered) ...[
                const SizedBox(height: TelmizoSpacing.md),
                WeeklyDayCard(
                  key: ValueKey(day.weekday),
                  draft: day,
                  enabled: !state.isBusy,
                  onChanged: () => setState(() {}),
                  onRemove: () => _toggle(day.weekday),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: TelmizoSpacing.lg),
                TelmizoInlineMessage(message: classesErrorMessage(error)),
              ],
              const SizedBox(height: TelmizoSpacing.xl),
              TelmizoPrimaryButton(
                key: const Key('save-weekly-schedule'),
                label: LocaleKeys.schedule_save.tr(),
                icon: Icons.bolt,
                isLoading: state.isRunning(ClassesAction.createSchedule),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
