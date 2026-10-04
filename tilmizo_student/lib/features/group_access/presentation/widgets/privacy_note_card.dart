import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

class PrivacyNoteCard extends StatelessWidget {
  const PrivacyNoteCard({super.key});

  @override
  Widget build(BuildContext context) => TelmizoInfoBox(
    icon: Icons.shield_outlined,
    title: LocaleKeys.privacy_title.tr(),
    body: LocaleKeys.privacy_body.tr(),
    background: TelmizoColors.surfaceContainer,
  );
}
