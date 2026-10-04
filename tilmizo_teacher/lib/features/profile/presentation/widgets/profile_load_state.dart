import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/teacher_profile.dart';
import '../controllers/current_profile_controller.dart';

/// Loading and retry states around the current profile.
class ProfileLoadState extends ConsumerWidget {
  const ProfileLoadState({super.key, required this.builder});

  final Widget Function(TeacherProfile profile) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(currentProfileProvider)
        .when(
          data: builder,
          loading: () => const TelmizoLoadingView(),
          error: (error, _) {
            final type = failureTypeOf(error);
            return TelmizoErrorView(
              title: LocaleKeys.splash_error_title.tr(),
              message: type == AppFailureType.notFound
                  ? LocaleKeys.error_profile_not_found.tr()
                  : appFailureMessage(type),
              retryLabel: LocaleKeys.common_retry.tr(),
              onRetry: () => ref.invalidate(currentProfileProvider),
            );
          },
        );
  }
}
