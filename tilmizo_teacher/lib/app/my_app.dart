import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/controllers/app_flow_controller.dart';
import '../generated/locale_keys.g.dart';
import '../router/app_router.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppRouter _router = ref.read(appRouterProvider);

  @override
  void initState() {
    super.initState();
    // Sign-out and session loss (for example a failed token refresh) replace
    // the whole stack with the login screen.
    ref.listenManual(authSessionStatusProvider, (previous, next) {
      final wasAuthenticated =
          previous?.value == AuthSessionStatus.authenticated;
      if (wasAuthenticated && next.value == AuthSessionStatus.unauthenticated) {
        ref.read(resetSessionDataProvider)();
        _router.replaceAll([PhoneLoginRoute()]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (_) => LocaleKeys.app_name.tr(),
      debugShowCheckedModeBanner: false,
      theme: TelmizoTheme.light(),
      routerConfig: _router.config(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) =>
          TelmizoMobileFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
