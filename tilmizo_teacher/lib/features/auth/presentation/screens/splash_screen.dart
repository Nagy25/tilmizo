import 'package:auto_route/auto_route.dart';
import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../router/app_destination_route.dart';
import '../../domain/app_destination.dart';
import '../controllers/app_flow_controller.dart';

/// The only startup screen: resolves the session and routes onward.
@RoutePage()
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<AppDestination>>(appStartupProvider, (_, next) {
      final destination = next.value;
      if (destination != null && mounted) {
        context.router.replaceAll([destination.route]);
      }
    }, fireImmediately: true);
  }

  void _retry() {
    ref.read(resetSessionDataProvider)();
    ref.invalidate(appStartupProvider);
  }

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(appStartupProvider);
    final textTheme = context.textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              Color(0xFFE6F7F6),
              TelmizoColors.surface,
              Color(0xFFFFF6EC),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TelmizoSpacing.lg),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: TelmizoSplashBrand(
                      badge: LocaleKeys.splash_badge.tr(),
                      name: LocaleKeys.brand_name.tr(),
                      audience: LocaleKeys.brand_teacher.tr(),
                      tagline: LocaleKeys.splash_tagline.tr(),
                      logoSemanticLabel: LocaleKeys.logo_semantics.tr(),
                    ),
                  ),
                ),
                if (startup.hasError && !startup.isLoading)
                  _StartupError(onRetry: _retry)
                else
                  const _LoadingPill(),
                const SizedBox(height: TelmizoSpacing.lg),
                Text(
                  '${LocaleKeys.splash_country.tr()}  •  '
                  '${LocaleKeys.splash_version.tr(args: [ref.watch(appVersionProvider)])}',
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: TelmizoColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TelmizoSpacing.lg,
          vertical: TelmizoSpacing.md - 4,
        ),
        decoration: const BoxDecoration(
          color: TelmizoColors.surfaceContainerLowest,
          borderRadius: TelmizoRadius.pillAll,
          boxShadow: TelmizoShadows.level1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: TelmizoSpacing.sm),
            Flexible(
              child: Text(
                LocaleKeys.splash_loading.tr(),
                style: context.textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TelmizoInlineMessage(
          title: LocaleKeys.splash_error_title.tr(),
          message: LocaleKeys.splash_error_message.tr(),
        ),
        const SizedBox(height: TelmizoSpacing.md),
        TelmizoPrimaryButton(
          label: LocaleKeys.common_retry.tr(),
          icon: Icons.refresh,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
