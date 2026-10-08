import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Confirms deleting a homework. Attached Resource files are kept.
Future<bool> confirmHomeworkDelete(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: TelmizoColors.error),
      title: Text(LocaleKeys.homework_delete_title.tr()),
      content: Text(LocaleKeys.homework_delete_body.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(LocaleKeys.common_cancel.tr()),
        ),
        FilledButton(
          key: const Key('confirm-homework-delete'),
          style: FilledButton.styleFrom(backgroundColor: TelmizoColors.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(LocaleKeys.homework_delete_confirm.tr()),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
