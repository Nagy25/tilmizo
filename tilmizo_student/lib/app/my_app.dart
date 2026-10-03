import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tilmizo_student/generated/locale_keys.g.dart';
import 'package:tilmizo_student/router/app_router.dart';

final AppRouter appRouter = AppRouter();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: LocaleKeys.app_name.tr(),
      routerConfig: appRouter.config(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
