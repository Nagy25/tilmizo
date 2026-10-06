import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/class_session.dart';
import '../controllers/classes_editor_controller.dart';
import '../formatting/session_formatting.dart';
import 'class_pickers.dart';
import 'edit_mode_selector.dart';
import 'session_dialogs.dart';
import 'session_location_fields.dart';

/// The reschedule, location, and cancel form for an editable session.
class SessionEditForm extends ConsumerStatefulWidget {
  const SessionEditForm({super.key, required this.session});

  final ClassSession session;

  @override
  ConsumerState<SessionEditForm> createState() => _SessionEditFormState();
}

class _SessionEditFormState extends ConsumerState<SessionEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _place;
  late final TextEditingController _link;
  late SessionLocationType _type;
  late DateTime _date;
  late ClockTime _start;
  late ClockTime _end;
  var _mode = SessionEditMode.reschedule;
  bool _invalidTime = false;

  ClassSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    final location = _session.location;
    _place = TextEditingController(text: location.physicalLocation);
    _link = TextEditingController(text: location.meetingLink);
    _type = location.type;
    final start = CairoTime.toCairo(_session.startsAt);
    final end = CairoTime.toCairo(_session.endsAt);
    _date = DateTime.utc(start.year, start.month, start.day);
    _start = ClockTime(start.hour, start.minute);
    _end = ClockTime(end.hour, end.minute);
  }

  @override
  void dispose() {
    _place.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _invalidTime = false);
    final editor = ref.read(classesEditorControllerProvider.notifier);
    ClassSession? result;
    String success = LocaleKeys.session_updated.tr();
    switch (_mode) {
      case SessionEditMode.reschedule:
        if (!(_formKey.currentState?.validate() ?? false)) return;
        final range = resolveCairoRange(_date, _start, _end);
        if (range == null) return setState(() => _invalidTime = true);
        if (range.startsAt == _session.startsAt &&
            range.endsAt == _session.endsAt) {
          return showTelmizoSnackBar(
            context,
            LocaleKeys.session_no_changes.tr(),
          );
        }
        result = await editor.reschedule(
          _session.id,
          startsAt: range.startsAt,
          endsAt: range.endsAt,
        );
      case SessionEditMode.location:
        if (!(_formKey.currentState?.validate() ?? false)) return;
        final location = SessionLocationFields.read(_type, _place, _link);
        if (location == null) return;
        if (location == _session.location) {
          return showTelmizoSnackBar(
            context,
            LocaleKeys.session_no_changes.tr(),
          );
        }
        result = await editor.changeLocation(_session.id, location);
      case SessionEditMode.cancel:
        if (!await confirmSessionCancel(context, _session)) return;
        result = await editor.cancel(_session.id);
        success = LocaleKeys.session_cancelled.tr();
    }
    if (result == null || !mounted) return;
    showTelmizoSnackBar(context, success);
    await context.router.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classesEditorControllerProvider);
    final now = ref.watch(clockProvider)();
    final enabled = !state.isBusy;
    final error = state.error;
    final isCancel = _mode == SessionEditMode.cancel;
    return Form(
      key: _formKey,
      child: TelmizoScrollBody(
        children: [
          TelmizoCard(
            padding: const EdgeInsets.all(TelmizoSpacing.md),
            child: Text(
              [
                _session.group.name,
                ?_session.group.subject,
                context.cairoDate(_session.startsAt),
                context.sessionTimeRange(_session),
              ].join(' · '),
              style: context.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          TelmizoInlineMessage(
            message: LocaleKeys.session_only_this_notice.tr(),
            tone: TelmizoMessageTone.info,
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoFieldLabel(label: LocaleKeys.session_edit_choose.tr()),
          EditModeSelector(
            selected: _mode,
            enabled: enabled,
            onChanged: (mode) => setState(() {
              _mode = mode;
              ref.read(classesEditorControllerProvider.notifier).clearError();
            }),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          if (_mode == SessionEditMode.reschedule) ...[
            CairoDateField(
              value: _date,
              now: now,
              enabled: enabled,
              onChanged: (date) => setState(() => _date = date),
            ),
            const SizedBox(height: TelmizoSpacing.md),
            ClockRangeFields(
              start: _start,
              end: _end,
              enabled: enabled,
              onStartChanged: (time) => setState(() => _start = time),
              onEndChanged: (time) => setState(() => _end = time),
            ),
            if (_invalidTime) ...[
              const SizedBox(height: TelmizoSpacing.md),
              TelmizoInlineMessage(
                message: LocaleKeys.session_time_invalid.tr(),
              ),
            ],
          ],
          if (_mode == SessionEditMode.location)
            SessionLocationFields(
              type: _type,
              enabled: enabled,
              placeController: _place,
              linkController: _link,
              onTypeChanged: (type) => setState(() => _type = type),
            ),
          if (error != null) ...[
            const SizedBox(height: TelmizoSpacing.md),
            TelmizoInlineMessage(message: classesErrorMessage(error)),
          ],
          const SizedBox(height: TelmizoSpacing.xl),
          if (isCancel)
            FilledButton.icon(
              key: const Key('submit-session-edit'),
              style: FilledButton.styleFrom(
                backgroundColor: TelmizoColors.error,
                minimumSize: const Size.fromHeight(TelmizoSpacing.buttonHeight),
              ),
              onPressed: enabled ? _submit : null,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(LocaleKeys.session_cancel_action.tr()),
            )
          else
            TelmizoPrimaryButton(
              key: const Key('submit-session-edit'),
              label: LocaleKeys.session_edit_save.tr(),
              icon: Icons.save_outlined,
              isLoading: state.isBusy,
              onPressed: _submit,
            ),
        ],
      ),
    );
  }
}
