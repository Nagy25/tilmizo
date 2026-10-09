import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/controllers/app_flow_controller.dart';
import '../features/group_access/data/approved_groups_memory.dart';
import '../features/notifications/presentation/widgets/app_notifications_host.dart';
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
    // Every authentication change clears cached student data. Sign-out and
    // session loss also replace the stack with the login screen.
    ref.listenManual(authSessionStatusProvider, (previous, next) {
      final status = next.value;
      if (status == null || status == previous?.value) return;
      if (previous?.value != null) ref.read(resetSessionDataProvider)();
      if (previous?.value == AuthSessionStatus.authenticated &&
          status == AuthSessionStatus.unauthenticated) {
        _router.replaceAll([PhoneLoginRoute()]);
        _forgetApprovedGroups();
      }
    });
  }

  /// Best effort: the display hint must never block returning to login.
  Future<void> _forgetApprovedGroups() async {
    try {
      await ref.read(approvedGroupsMemoryProvider).clear();
    } catch (_) {
      // Storage unavailable; the hint only affects wording.
    }
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
      builder: (context, child) => TelmizoMobileFrame(
        child: AppNotificationsHost(
          router: _router,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
