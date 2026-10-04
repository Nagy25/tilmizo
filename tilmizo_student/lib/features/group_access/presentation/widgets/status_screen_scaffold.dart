import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_router.dart';

/// Shared frame for group status screens: header with a way back to the
/// groups list and a scrollable body.
class StatusScreenScaffold extends StatelessWidget {
  const StatusScreenScaffold({
    super.key,
    required this.subtitle,
    required this.body,
  });

  final String subtitle;
  final Widget body;

  static void backToGroups(BuildContext context) {
    final router = context.router;
    if (router.canPop()) {
      router.pop();
    } else {
      router.replaceAll([const GroupsHomeRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: LocaleKeys.app_name.tr(),
        subtitle: subtitle,
        showBack: true,
        onBack: () => backToGroups(context),
      ),
      body: body,
    );
  }
}
