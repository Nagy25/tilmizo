import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../domain/class_session.dart';

/// Optional class note shared by the whole session (not per student).
class SessionNotesField extends StatelessWidget {
  const SessionNotesField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TelmizoFormField(
    label: LocaleKeys.session_notes_label.tr(),
    qualifier: LocaleKeys.common_optional.tr(),
    child: TextFormField(
      key: const Key('session-notes-field'),
      controller: controller,
      enabled: enabled,
      minLines: 3,
      maxLines: 6,
      maxLength: ClassSession.maxNotesLength,
      decoration: InputDecoration(hintText: LocaleKeys.session_notes_hint.tr()),
      validator: (value) =>
          (value?.trim().length ?? 0) > ClassSession.maxNotesLength
          ? LocaleKeys.session_notes_too_long.tr()
          : null,
    ),
  );
}
