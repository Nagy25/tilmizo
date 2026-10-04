import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../auth/presentation/controllers/app_flow_controller.dart';
import '../controllers/profile_form_controller.dart';
import '../widgets/profile_form.dart';
import '../widgets/profile_load_state.dart';

@RoutePage()
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _save({
    required String fullName,
    required String teachingSubject,
  }) async {
    final saved = await ref
        .read(profileFormControllerProvider.notifier)
        .submit(fullName: fullName, teachingSubject: teachingSubject);
    if (saved != null && mounted) {
      showTelmizoSnackBar(context, LocaleKeys.profile_saved.tr());
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.profile_logout_confirm_title.tr()),
        content: Text(LocaleKeys.profile_logout_confirm_body.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocaleKeys.common_cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: TelmizoColors.error),
            child: Text(LocaleKeys.profile_logout.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);
    final router = context.router;
    try {
      await ref.read(phoneAuthServiceProvider).signOut();
      ref.read(resetSessionDataProvider)();
      await router.replaceAll([PhoneLoginRoute()]);
    } on AuthFailure {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      showTelmizoSnackBar(context, LocaleKeys.profile_logout_failed.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(profileFormControllerProvider);

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.profile_edit_title.tr(),
        subtitle: LocaleKeys.profile_edit_subtitle.tr(),
        showBack: true,
      ),
      body: ProfileLoadState(
        builder: (profile) => TelmizoScrollBody(
          children: [
            ProfileForm(
              profile: profile,
              submitLabel: LocaleKeys.profile_save.tr(),
              submitIcon: Icons.save_outlined,
              isSaving: formState.isSaving,
              failure: formState.failure,
              onSubmit: _save,
            ),
            const SizedBox(height: TelmizoSpacing.xl),
            const Divider(),
            const SizedBox(height: TelmizoSpacing.md),
            SizedBox(
              height: TelmizoSpacing.buttonHeight,
              child: TextButton.icon(
                onPressed: _isSigningOut || formState.isSaving
                    ? null
                    : _signOut,
                style: TextButton.styleFrom(
                  foregroundColor: TelmizoColors.error,
                ),
                icon: _isSigningOut
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(LocaleKeys.profile_logout.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
