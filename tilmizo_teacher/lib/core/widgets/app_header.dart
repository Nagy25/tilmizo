import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../generated/locale_keys.g.dart';

/// The shared [TelmizoAppHeader] with the teacher app's localized labels.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) => TelmizoAppHeader(
    title: title,
    subtitle: subtitle,
    showBack: showBack,
    onBack: onBack,
    trailing: trailing,
    backTooltip: LocaleKeys.common_back.tr(),
    logoSemanticLabel: LocaleKeys.logo_semantics.tr(),
  );
}
