import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Title and optional description, limited as the backend columns are.
class ResourceDetailFields extends StatelessWidget {
  const ResourceDetailFields({
    super.key,
    required this.title,
    required this.description,
    required this.enabled,
  });

  final TextEditingController title;
  final TextEditingController description;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TelmizoFormField(
        label: LocaleKeys.resource_form_title_label.tr(),
        isRequired: true,
        child: TextFormField(
          key: const Key('resource-title'),
          controller: title,
          enabled: enabled,
          maxLength: resourceTitleMaxLength,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: LocaleKeys.resource_form_title_hint.tr(),
            counterText: '',
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return LocaleKeys.resource_form_title_required.tr();
            }
            if (text.length > resourceTitleMaxLength) {
              return LocaleKeys.resource_form_title_too_long.tr(
                args: ['$resourceTitleMaxLength'],
              );
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: TelmizoSpacing.lg),
      TelmizoFormField(
        label: LocaleKeys.resource_form_description_label.tr(),
        qualifier: LocaleKeys.common_optional.tr(),
        child: TextFormField(
          key: const Key('resource-description'),
          controller: description,
          enabled: enabled,
          minLines: 3,
          maxLines: 6,
          maxLength: resourceDescriptionMaxLength,
          decoration: InputDecoration(
            hintText: LocaleKeys.resource_form_description_hint.tr(),
          ),
        ),
      ),
    ],
  );
}

/// The HTTPS link for link types; validated locally and by the backend.
class ResourceUrlField extends StatelessWidget {
  const ResourceUrlField({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TelmizoFormField(
    label: LocaleKeys.resource_form_url_label.tr(),
    isRequired: true,
    child: TextFormField(
      key: const Key('resource-url'),
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.url,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      maxLength: resourceUrlMaxLength,
      decoration: InputDecoration(
        hintText: 'https://',
        helperText: LocaleKeys.resource_form_url_note.tr(),
        helperMaxLines: 2,
        prefixIcon: const Icon(Icons.link),
        counterText: '',
      ),
      validator: (value) => isValidHttpsUrl(value?.trim())
          ? null
          : LocaleKeys.resource_form_url_invalid.tr(),
    ),
  );
}
