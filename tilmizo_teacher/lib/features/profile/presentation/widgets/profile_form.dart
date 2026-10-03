import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/teacher_profile.dart';
import 'avatar_card.dart';
import 'suggestion_chips.dart';
import 'verified_phone_field.dart';

typedef ProfileSubmit = void Function({
  required String fullName,
  required String teachingSubject,
});

/// Profile fields shared by completion and edit modes.
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.profile,
    required this.submitLabel,
    required this.submitIcon,
    required this.isSaving,
    required this.onSubmit,
    this.failure,
  });

  final TeacherProfile profile;
  final String submitLabel;
  final IconData submitIcon;
  final bool isSaving;
  final AppFailureType? failure;
  final ProfileSubmit onSubmit;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _subject = TextEditingController(
    text: widget.profile.teachingSubject,
  );

  @override
  void dispose() {
    _name.dispose();
    _subject.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(fullName: _name.text, teachingSubject: _subject.text);
  }

  String? _required(String? value, String message) =>
      (value?.trim().isEmpty ?? true) ? message : null;

  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AvatarCard(avatarUrl: widget.profile.avatarUrl),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoFormField(
            label: LocaleKeys.profile_name_label.tr(),
            isRequired: true,
            qualifier: LocaleKeys.profile_name_caption.tr(),
            child: TextFormField(
              key: const Key('profile-name'),
              controller: _name,
              enabled: !widget.isSaving,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              maxLength: 80,
              decoration: InputDecoration(
                hintText: LocaleKeys.profile_name_hint.tr(),
                counterText: '',
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              validator: (value) =>
                  _required(value, LocaleKeys.profile_name_required.tr()),
            ),
          ),
          const SizedBox(height: TelmizoSpacing.lg),
          VerifiedPhoneField(phone: widget.profile.phone),
          const SizedBox(height: TelmizoSpacing.lg),
          TelmizoFormField(
            label: LocaleKeys.profile_subject_label.tr(),
            isRequired: true,
            qualifier: LocaleKeys.profile_subject_caption.tr(),
            child: TextFormField(
              key: const Key('profile-subject'),
              controller: _subject,
              enabled: !widget.isSaving,
              textInputAction: TextInputAction.done,
              maxLength: 80,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: LocaleKeys.profile_subject_hint.tr(),
                counterText: '',
                prefixIcon: const Icon(Icons.functions),
              ),
              validator: (value) =>
                  _required(value, LocaleKeys.profile_subject_required.tr()),
            ),
          ),
          const SizedBox(height: TelmizoSpacing.md),
          Text(
            LocaleKeys.profile_subject_suggestions.tr(),
            style: context.textTheme.labelMedium?.copyWith(
              color: TelmizoColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TelmizoSpacing.sm),
          SuggestionChips(
            controller: _subject,
            enabled: !widget.isSaving,
            suggestions: [
              LocaleKeys.subject_math.tr(),
              LocaleKeys.subject_arabic.tr(),
              LocaleKeys.subject_english.tr(),
              LocaleKeys.subject_physics.tr(),
              LocaleKeys.subject_chemistry.tr(),
              LocaleKeys.subject_biology.tr(),
              LocaleKeys.subject_science.tr(),
            ],
          ),
          if (failure != null) ...[
            const SizedBox(height: TelmizoSpacing.lg),
            TelmizoInlineMessage(
              message: failure == AppFailureType.notFound
                  ? LocaleKeys.error_profile_not_found.tr()
                  : appFailureMessage(failure),
            ),
          ],
          const SizedBox(height: TelmizoSpacing.xl),
          TelmizoPrimaryButton(
            label: widget.submitLabel,
            icon: widget.submitIcon,
            isLoading: widget.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
