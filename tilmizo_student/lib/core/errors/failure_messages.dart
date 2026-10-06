import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../generated/locale_keys.g.dart';

/// Localized, user-safe message for a data-access failure.
String appFailureMessage(AppFailureType type) => switch (type) {
  AppFailureType.network => LocaleKeys.error_network,
  AppFailureType.sessionExpired => LocaleKeys.error_session_expired,
  AppFailureType.notEligible => LocaleKeys.error_not_eligible,
  AppFailureType.notFound ||
  AppFailureType.rejected ||
  AppFailureType.invalidInput ||
  AppFailureType.duplicateInviteCode => LocaleKeys.error_rejected,
  AppFailureType.unknown => LocaleKeys.error_unknown,
}.tr();

AppFailureType failureTypeOf(Object? error) =>
    error is AppFailure ? error.type : AppFailureType.unknown;

String profileAvatarFailureMessage(ProfileAvatarFailureType type) =>
    switch (type) {
      ProfileAvatarFailureType.unsupportedFormat =>
        LocaleKeys.profile_avatar_unsupported,
      ProfileAvatarFailureType.tooLarge => LocaleKeys.profile_avatar_too_large,
      ProfileAvatarFailureType.network ||
      ProfileAvatarFailureType.unauthenticated ||
      ProfileAvatarFailureType.rejected ||
      ProfileAvatarFailureType.unknown =>
        LocaleKeys.profile_avatar_upload_failed,
    }.tr();
