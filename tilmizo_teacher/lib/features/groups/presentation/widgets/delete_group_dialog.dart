import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

/// Arabic confirmation before permanently deleting a group.
Future<bool> confirmGroupDeletion(
  BuildContext context,
  String groupName,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_outline, color: TelmizoColors.error),
      title: Text(LocaleKeys.delete_group_title.tr()),
      content: Text(LocaleKeys.delete_group_body.tr(args: [groupName])),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(LocaleKeys.common_cancel.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: TelmizoColors.error,
            minimumSize: const Size(TelmizoSpacing.minTouchTarget, 48),
          ),
          child: Text(LocaleKeys.delete_group_confirm.tr()),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
