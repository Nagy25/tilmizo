import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/form_screen_body.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../controllers/profile_form_controller.dart';
import '../widgets/profile_form.dart';
import '../widgets/profile_load_state.dart';

/// Shown only while the profile is incomplete; there is no way back past it.
@RoutePage()
class CompleteProfileScreen extends ConsumerWidget {
  const CompleteProfileScreen({super.key});

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref, {
    required String fullName,
    required String teachingSubject,
  }) async {
    final saved = await ref
        .read(profileFormControllerProvider.notifier)
        .submit(fullName: fullName, teachingSubject: teachingSubject);
    if (saved == null || !context.mounted) return;

    final router = context.router;
    try {
      final groups = await ref.read(groupsControllerProvider.future);
      await router.replaceAll([
        groups.isEmpty
            ? const EmptyGroupsRoute()
            : const GroupsDashboardRoute(),
      ]);
    } on AppFailure {
      await router.replaceAll([const SplashRoute()]);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(profileFormControllerProvider);
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.app_name.tr(),
        subtitle: LocaleKeys.profile_complete_title.tr(),
      ),
      body: ProfileLoadState(
        builder: (profile) => FormScreenBody(
          children: [
            Text(
              LocaleKeys.profile_complete_title.tr(),
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: TelmizoSpacing.xs),
            Text(
              LocaleKeys.profile_complete_subtitle.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: TelmizoColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TelmizoSpacing.lg),
            ProfileForm(
              profile: profile,
              submitLabel: LocaleKeys.profile_save_continue.tr(),
              submitIcon: Icons.arrow_back,
              isSaving: formState.isSaving,
              failure: formState.failure,
              onSubmit: ({required fullName, required teachingSubject}) =>
                  _submit(
                    context,
                    ref,
                    fullName: fullName,
                    teachingSubject: teachingSubject,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
