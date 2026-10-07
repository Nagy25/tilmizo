import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../payments/presentation/widgets/payment_amount_field.dart';
import '../../domain/one_time_session_draft.dart';
import '../controllers/classes_editor_controller.dart';
import '../formatting/session_formatting.dart';
import '../widgets/active_group_gate.dart';
import '../widgets/class_pickers.dart';
import '../widgets/session_location_fields.dart';
import '../widgets/session_notes_field.dart';

/// Creates a single session that does not affect the weekly schedule.
@RoutePage()
class OneTimeSessionScreen extends ConsumerStatefulWidget {
  const OneTimeSessionScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  ConsumerState<OneTimeSessionScreen> createState() =>
      _OneTimeSessionScreenState();
}

class _OneTimeSessionScreenState extends ConsumerState<OneTimeSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _place = TextEditingController();
  final _link = TextEditingController();
  final _notes = TextEditingController();
  final _payment = TextEditingController();
  var _type = SessionLocationType.physical;
  DateTime? _date;
  ClockTime? _start;
  ClockTime? _end;
  bool _invalidTime = false;

  @override
  void dispose() {
    _place.dispose();
    _link.dispose();
    _notes.dispose();
    _payment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _invalidTime = false);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final (date, start, end) = (_date, _start, _end);
    final location = SessionLocationFields.read(_type, _place, _link);
    if (date == null || start == null || end == null || location == null) {
      return;
    }
    final range = resolveCairoRange(date, start, end);
    if (range == null) {
      setState(() => _invalidTime = true);
      return;
    }
    final created = await ref
        .read(classesEditorControllerProvider.notifier)
        .createSession(
          OneTimeSessionDraft(
            groupId: widget.groupId,
            startsAt: range.startsAt,
            endsAt: range.endsAt,
            location: location,
            notes: trimToNull(_notes.text),
            // Empty means no amount: the original no-payment RPC is used.
            paymentAmount: PaymentAmountField.read(_payment),
          ),
        );
    if (created == null || !mounted) return;
    showTelmizoSnackBar(context, LocaleKeys.one_time_created.tr());
    await context.router.replace(SessionDetailsRoute(sessionId: created.id));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classesEditorControllerProvider);
    final now = ref.watch(clockProvider)();
    final enabled = !state.isBusy;
    final error = state.error;

    return Scaffold(
      appBar: AppHeader(title: LocaleKeys.one_time_title.tr(), showBack: true),
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
                message: LocaleKeys.one_time_banner.tr(),
                tone: TelmizoMessageTone.info,
              ),
              const SizedBox(height: TelmizoSpacing.lg),
              Text(
                LocaleKeys.session_time_section.tr(),
                style: context.textTheme.titleMedium,
              ),
              const SizedBox(height: TelmizoSpacing.md),
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
              const SizedBox(height: TelmizoSpacing.sm),
              Text(
                LocaleKeys.classes_cairo_time_note.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: TelmizoColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TelmizoSpacing.lg),
              SessionLocationFields(
                type: _type,
                enabled: enabled,
                placeController: _place,
                linkController: _link,
                onTypeChanged: (type) => setState(() => _type = type),
              ),
              const SizedBox(height: TelmizoSpacing.lg),
              SessionNotesField(controller: _notes, enabled: enabled),
              const SizedBox(height: TelmizoSpacing.lg),
              PaymentAmountField(
                controller: _payment,
                enabled: enabled,
                isRequired: false,
                fieldKey: const Key('session-payment-amount'),
                label: LocaleKeys.session_payment_amount_label.tr(),
                hint: LocaleKeys.session_payment_amount_hint.tr(),
              ),
              const SizedBox(height: TelmizoSpacing.xs),
              Text(
                LocaleKeys.session_payment_note.tr(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: TelmizoColors.onSurfaceVariant,
                ),
              ),
              if (_invalidTime) ...[
                const SizedBox(height: TelmizoSpacing.md),
                TelmizoInlineMessage(
                  message: LocaleKeys.session_time_invalid.tr(),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: TelmizoSpacing.md),
                TelmizoInlineMessage(message: classesErrorMessage(error)),
              ],
              const SizedBox(height: TelmizoSpacing.xl),
              TelmizoPrimaryButton(
                key: const Key('create-one-time-session'),
                label: LocaleKeys.one_time_submit.tr(),
                icon: Icons.event_available_outlined,
                isLoading: state.isRunning(ClassesAction.createSession),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
