import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/invite_code_generator.dart';
import 'active_toggle_tile.dart';
import 'group_form_controllers.dart';

/// Schema-backed group fields: name, subject, grade, invite code, and status.
class GroupFormFields extends StatelessWidget {
  const GroupFormFields({
    super.key,
    required this.controllers,
    required this.enabled,
    this.subjectHelper,
    this.inviteCodeError,
  });

  final GroupFormControllers controllers;
  final bool enabled;
  final String? subjectHelper;
  final String? inviteCodeError;

  @override
  Widget build(BuildContext context) {
    final optional = LocaleKeys.common_optional.tr();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TelmizoFormField(
          label: LocaleKeys.group_name_label.tr(),
          isRequired: true,
          child: TextFormField(
            key: const Key('group-name'),
            controller: controllers.name,
            enabled: enabled,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: LocaleKeys.group_name_hint.tr(),
              helperText: LocaleKeys.group_name_tip.tr(),
              counterText: '',
            ),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? LocaleKeys.group_name_required.tr()
                : null,
          ),
        ),
        const SizedBox(height: TelmizoSpacing.lg),
        TelmizoFormField(
          label: LocaleKeys.group_subject_label.tr(),
          qualifier: optional,
          child: TextFormField(
            key: const Key('group-subject'),
            controller: controllers.subject,
            enabled: enabled,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: LocaleKeys.group_subject_hint.tr(),
              helperText: subjectHelper,
              counterText: '',
              prefixIcon: const Icon(Icons.menu_book_outlined),
            ),
          ),
        ),
        const SizedBox(height: TelmizoSpacing.lg),
        TelmizoFormField(
          label: LocaleKeys.group_grade_label.tr(),
          qualifier: optional,
          child: TextFormField(
            key: const Key('group-grade'),
            controller: controllers.grade,
            enabled: enabled,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: LocaleKeys.group_grade_hint.tr(),
              counterText: '',
              prefixIcon: const Icon(Icons.school_outlined),
            ),
          ),
        ),
        const SizedBox(height: TelmizoSpacing.lg),
        TelmizoFormField(
          label: LocaleKeys.group_invite_label.tr(),
          qualifier: optional,
          trailing: TextButton.icon(
            onPressed: enabled
                ? () => controllers.inviteCode.text = generateInviteCode()
                : null,
            icon: const Icon(Icons.casino_outlined, size: 18),
            label: Text(LocaleKeys.group_invite_generate.tr()),
          ),
          child: TextFormField(
            key: const Key('group-invite-code'),
            controller: controllers.inviteCode,
            enabled: enabled,
            maxLength: 32,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            style: context.textTheme.headlineSmall?.copyWith(
              color: TelmizoColors.primary,
              letterSpacing: 1.5,
            ),
            decoration: InputDecoration(
              hintText: LocaleKeys.group_invite_hint.tr(),
              // The Arabic "example:" prefix reads right-to-left even
              // though codes are typed left-to-right.
              hintTextDirection: TextDirection.rtl,
              helperText: LocaleKeys.group_invite_help.tr(),
              errorText: inviteCodeError,
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: TelmizoSpacing.lg),
        ActiveToggleTile(notifier: controllers.isActive, enabled: enabled),
      ],
    );
  }
}
