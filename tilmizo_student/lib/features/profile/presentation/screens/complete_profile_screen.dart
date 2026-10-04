import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';
import '../../../auth/presentation/controllers/app_flow_controller.dart';
import '../../../group_access/presentation/controllers/group_access_providers.dart';
import '../../../../router/student_destination_route.dart';
import '../controllers/current_profile_controller.dart';
import '../controllers/profile_form_controller.dart';

/// Student profile completion: name required, verified phone read-only, and
/// an optional avatar placeholder. No teaching subject for students.
@RoutePage()
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final router = context.router;
    final saved = await ref
        .read(profileFormControllerProvider.notifier)
        .submit(_name.text);
    if (saved == null || !mounted) return;
    try {
      final entries = await ref.read(groupAccessOverviewProvider.future);
      await router.replaceAll(flowForEntries(entries).routes);
    } on AppFailure {
      await router.replaceAll([const SplashRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final form = ref.watch(profileFormControllerProvider);
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.app_name.tr(),
        subtitle: LocaleKeys.profile_complete_title.tr(),
      ),
      body: profile.when(
        loading: () => const TelmizoLoadingView(),
        error: (error, _) => TelmizoErrorView(
          title: LocaleKeys.splash_error_title.tr(),
          message: failureTypeOf(error) == AppFailureType.notFound
              ? LocaleKeys.error_profile_not_found.tr()
              : appFailureMessage(failureTypeOf(error)),
          retryLabel: LocaleKeys.common_retry.tr(),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) => Form(
          key: _formKey,
          child: TelmizoScrollBody(
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
              TelmizoAvatarCard(
                avatarUrl: profile.avatarUrl,
                title: LocaleKeys.profile_avatar_title.tr(),
                body: LocaleKeys.profile_avatar_body.tr(),
                semanticLabel: LocaleKeys.profile_avatar_semantics.tr(),
              ),
              const SizedBox(height: TelmizoSpacing.lg),
              TelmizoFormField(
                label: LocaleKeys.profile_name_label.tr(),
                isRequired: true,
                qualifier: LocaleKeys.profile_name_caption.tr(),
                child: TextFormField(
                  key: const Key('profile-name'),
                  controller: _name,
                  enabled: !form.isSaving,
                  maxLength: 80,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.profile_name_hint.tr(),
                    counterText: '',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? LocaleKeys.profile_name_required.tr()
                      : null,
                ),
              ),
              const SizedBox(height: TelmizoSpacing.lg),
              VerifiedPhoneField(
                phone: profile.phone,
                label: LocaleKeys.profile_phone_label.tr(),
                note: LocaleKeys.profile_phone_note.tr(),
              ),
              if (form.failure case final failure?) ...[
                const SizedBox(height: TelmizoSpacing.lg),
                TelmizoInlineMessage(message: appFailureMessage(failure)),
              ],
              const SizedBox(height: TelmizoSpacing.xl),
              TelmizoPrimaryButton(
                label: LocaleKeys.profile_save_continue.tr(),
                icon: Icons.arrow_forward,
                isLoading: form.isSaving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
