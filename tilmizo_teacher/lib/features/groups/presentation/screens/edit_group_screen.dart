import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/teacher_group.dart';
import '../controllers/group_editor_controller.dart';
import '../controllers/groups_controller.dart';
import '../widgets/archive_group_dialog.dart';
import '../widgets/group_form_controllers.dart';
import '../widgets/group_form_fields.dart';
import '../widgets/group_suspension_card.dart';

@RoutePage()
class EditGroupScreen extends ConsumerWidget {
  const EditGroupScreen({
    super.key,
    @PathParam('groupId') required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupDetailsProvider(groupId));
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.edit_group_title.tr(),
        showBack: true,
      ),
      body: group.when(
        skipLoadingOnRefresh: true,
        loading: () => const TelmizoLoadingView(),
        error: (error, _) {
          final failure = failureTypeOf(error);
          return TelmizoErrorView(
            title: failure == AppFailureType.notFound
                ? LocaleKeys.group_not_found_title.tr()
                : LocaleKeys.groups_load_error_title.tr(),
            message: failure == AppFailureType.notFound
                ? LocaleKeys.group_not_found_body.tr()
                : appFailureMessage(failure),
            retryLabel: LocaleKeys.common_retry.tr(),
            onRetry: () => ref.invalidate(groupDetailsProvider(groupId)),
          );
        },
        data: (group) => _EditGroupForm(key: ValueKey(group.id), group: group),
      ),
    );
  }
}

class _EditGroupForm extends ConsumerStatefulWidget {
  const _EditGroupForm({super.key, required this.group});

  final TeacherGroup group;

  @override
  ConsumerState<_EditGroupForm> createState() => _EditGroupFormState();
}

class _EditGroupFormState extends ConsumerState<_EditGroupForm> {
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
    final updated = await ref
        .read(groupEditorControllerProvider.notifier)
        .update(widget.group.id, draft);
    if (!mounted || updated == null) return;
    ref.invalidate(groupDetailsProvider(widget.group.id));
    showTelmizoSnackBar(context, LocaleKeys.edit_group_saved.tr());
    await context.router.maybePop();
  }

  Future<void> _archive() async {
    final confirmed = await confirmGroupArchive(context, widget.group.name);
    if (!confirmed || !mounted) return;
    final archived = await ref
        .read(groupEditorControllerProvider.notifier)
        .archive(widget.group.id);
    if (!mounted || archived == null) return;
    ref.invalidate(groupDetailsProvider(widget.group.id));
    showTelmizoSnackBar(context, LocaleKeys.archive_group_success.tr());
    await context.router.maybePop();
  }

  Future<void> _toggleSuspension() async {
    final suspend = !widget.group.isSuspended;
    final confirmed = await confirmGroupSuspension(context, suspend: suspend);
    if (!confirmed || !mounted) return;
    final updated = await ref
        .read(groupEditorControllerProvider.notifier)
        .setSuspended(widget.group.id, suspended: suspend);
    if (!mounted || updated == null) return;
    ref.invalidate(groupDetailsProvider(widget.group.id));
    showTelmizoSnackBar(
      context,
      suspend
          ? LocaleKeys.group_suspended_success.tr()
          : LocaleKeys.group_resumed_success.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupEditorControllerProvider);
    final failure = state.failure;
    return Form(
      key: _formKey,
      child: TelmizoScrollBody(
        children: [
          TelmizoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  LocaleKeys.edit_group_info_title.tr(),
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: TelmizoSpacing.lg),
                GroupFormFields(
                  controllers: _form,
                  enabled: !state.isBusy,
                  inviteCodeError: failure == AppFailureType.duplicateInviteCode
                      ? LocaleKeys.error_duplicate_invite.tr()
                      : null,
                ),
              ],
            ),
          ),
          if (failure != null &&
              failure != AppFailureType.duplicateInviteCode) ...[
            const SizedBox(height: TelmizoSpacing.lg),
            TelmizoInlineMessage(message: appFailureMessage(failure)),
          ],
          const SizedBox(height: TelmizoSpacing.xl),
          TelmizoPrimaryButton(
            label: LocaleKeys.edit_group_save.tr(),
            icon: Icons.save_outlined,
            isLoading: state.isSubmitting,
            onPressed: state.isBusy ? null : _save,
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          TextButton(
            onPressed: state.isBusy ? null : () => context.router.maybePop(),
            child: Text(LocaleKeys.edit_group_discard.tr()),
          ),
          if (widget.group.isActive) ...[
            const SizedBox(height: TelmizoSpacing.lg),
            GroupSuspensionCard(
              group: widget.group,
              isBusy: state.isBusy,
              isLoading: state.isSuspending,
              onToggle: _toggleSuspension,
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            TextButton.icon(
              onPressed: state.isBusy ? null : _archive,
              style: TextButton.styleFrom(foregroundColor: TelmizoColors.error),
              icon: state.isArchiving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.archive_outlined),
              label: Text(LocaleKeys.archive_group.tr()),
            ),
          ],
        ],
      ),
    );
  }
}
