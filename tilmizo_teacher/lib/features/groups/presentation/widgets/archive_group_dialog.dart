import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

Future<bool> confirmGroupArchive(BuildContext context, String groupName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.archive_outlined, color: TelmizoColors.primary),
      title: Text(LocaleKeys.archive_group_title.tr()),
      content: Text(LocaleKeys.archive_group_body.tr(args: [groupName])),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(LocaleKeys.common_cancel.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(LocaleKeys.archive_group_confirm.tr()),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
