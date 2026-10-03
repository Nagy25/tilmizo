import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/form_screen_body.dart';
import '../../../../core/widgets/snackbars.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../profile/presentation/controllers/current_profile_controller.dart';
import '../controllers/group_editor_controller.dart';
import '../widgets/group_form_controllers.dart';
import '../widgets/group_form_fields.dart';

@RoutePage()
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final GroupFormControllers _form;
  late final bool _subjectPrefilled;

  @override
  void initState() {
    super.initState();
    final specialization = ref
        .read(currentProfileProvider)
        .value
        ?.teachingSubject;
    _subjectPrefilled = specialization != null;
    _form = GroupFormControllers(subject: specialization);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = _form.toDraft();
    if (draft == null) return;

    final created = await ref
        .read(groupEditorControllerProvider.notifier)
        .create(draft);
    if (created == null || !mounted) return;
    showAppSnackBar(context, LocaleKeys.create_group_success.tr());
    await context.router.replaceAll([const GroupsDashboardRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupEditorControllerProvider);
    final failure = state.failure;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.app_name.tr(),
        subtitle: LocaleKeys.create_group_title.tr(),
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: FormScreenBody(
          children: [
            Text(
              LocaleKeys.create_group_title.tr(),
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: TelmizoSpacing.xs),
            Text(
              LocaleKeys.create_group_subtitle.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            GroupFormFields(
              controllers: _form,
              enabled: !state.isBusy,
              subjectHelper: _subjectPrefilled
                  ? LocaleKeys.group_subject_prefilled.tr()
                  : null,
              inviteCodeError: failure == AppFailureType.duplicateInviteCode
                  ? LocaleKeys.error_duplicate_invite.tr()
                  : null,
            ),
            if (failure != null &&
                failure != AppFailureType.duplicateInviteCode) ...[
              const SizedBox(height: TelmizoSpacing.lg),
              TelmizoInlineMessage(message: appFailureMessage(failure)),
            ],
            const SizedBox(height: TelmizoSpacing.xl),
            TelmizoPrimaryButton(
              label: LocaleKeys.create_group_submit.tr(),
              icon: Icons.add_circle_outline,
              isLoading: state.isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
