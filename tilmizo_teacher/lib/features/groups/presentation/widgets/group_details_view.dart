import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/form_screen_body.dart';
import '../../../../core/widgets/snackbars.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../domain/teacher_group.dart';
import '../controllers/group_editor_controller.dart';
import '../controllers/groups_controller.dart';
import 'delete_group_dialog.dart';
import 'group_form_controllers.dart';
import 'group_form_fields.dart';
import 'group_overview_card.dart';
import 'invite_code_card.dart';

/// Group overview, invite sharing, edit form, and deletion.
class GroupDetailsView extends ConsumerStatefulWidget {
  const GroupDetailsView({
    super.key,
    required this.group,
    required this.onGroupMissing,
  });

  final TeacherGroup group;
  final VoidCallback onGroupMissing;

  @override
  ConsumerState<GroupDetailsView> createState() => _GroupDetailsViewState();
}

class _GroupDetailsViewState extends ConsumerState<GroupDetailsView> {
  final _formKey = GlobalKey<FormState>();
  late final _form = GroupFormControllers.fromGroup(widget.group);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = _form.toDraft();
    if (draft == null) return;

    final editor = ref.read(groupEditorControllerProvider.notifier);
    final updated = await editor.update(widget.group.id, draft);
    if (!mounted) return;
    if (updated != null) {
      ref.invalidate(groupDetailsProvider(widget.group.id));
      showAppSnackBar(context, LocaleKeys.edit_group_saved.tr());
    } else if (ref.read(groupEditorControllerProvider).failure ==
        AppFailureType.notFound) {
      showAppSnackBar(context, LocaleKeys.error_group_not_found.tr());
      widget.onGroupMissing();
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmGroupDeletion(context, widget.group.name);
    if (!confirmed || !mounted) return;

    final router = context.router;
    final hasRemaining = await ref
        .read(groupEditorControllerProvider.notifier)
        .delete(widget.group.id);
    if (hasRemaining == null || !mounted) return;
    showAppSnackBar(context, LocaleKeys.delete_group_success.tr());
    await router.replaceAll([
      hasRemaining ? const GroupsDashboardRoute() : const EmptyGroupsRoute(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupEditorControllerProvider);
    final failure = state.failure;
    final group = widget.group;

    return Form(
      key: _formKey,
      child: FormScreenBody(
        children: [
          GroupOverviewCard(group: group),
          const SizedBox(height: TelmizoSpacing.lg),
          InviteCodeCard(groupName: group.name, inviteCode: group.inviteCode),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  LocaleKeys.edit_group_title.tr(),
                  style: context.textTheme.headlineSmall,
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                GroupFormFields(
                  controllers: _form,
                  enabled: !state.isBusy,
                  inviteCodeError: failure == AppFailureType.duplicateInviteCode
                      ? LocaleKeys.error_duplicate_invite.tr()
                      : null,
                ),
                if (failure != null &&
                    failure != AppFailureType.duplicateInviteCode) ...[
                  const SizedBox(height: TelmizoSpacing.lg),
                  TelmizoInlineMessage(message: appFailureMessage(failure)),
                ],
                const SizedBox(height: TelmizoSpacing.lg),
                TelmizoPrimaryButton(
                  label: LocaleKeys.edit_group_save.tr(),
                  icon: Icons.save_outlined,
                  isLoading: state.isSubmitting,
                  onPressed: state.isBusy ? null : _save,
                ),
                const SizedBox(height: TelmizoSpacing.sm),
                TextButton(
                  onPressed: state.isBusy
                      ? null
                      : () {
                          _form.reset(group);
                          ref
                              .read(groupEditorControllerProvider.notifier)
                              .clearFailure();
                        },
                  child: Text(LocaleKeys.edit_group_discard.tr()),
                ),
              ],
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          SizedBox(
            height: TelmizoSpacing.buttonHeight,
            child: TextButton.icon(
              onPressed: state.isBusy ? null : _delete,
              style: TextButton.styleFrom(foregroundColor: TelmizoColors.error),
              icon: state.isDeleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(LocaleKeys.delete_group.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
