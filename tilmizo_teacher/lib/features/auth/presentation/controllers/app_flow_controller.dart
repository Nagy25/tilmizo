import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../groups/presentation/controllers/groups_controller.dart';
import '../../../profile/presentation/controllers/current_profile_controller.dart';
import '../../domain/app_destination.dart';

/// Resolves the destination for the current session: login without a
/// session, profile completion for an incomplete profile, otherwise the empty
/// or populated groups screen.
///
/// Throws [AppFailure] for recoverable failures such as being offline.
Future<AppDestination> resolveAppDestination(Ref ref) async {
  final auth = ref.read(phoneAuthServiceProvider);
  if (!auth.isAuthenticated) return AppDestination.phoneLogin;

  try {
    final profile = await ref.read(currentProfileProvider.future);
    if (!profile.isComplete) return AppDestination.completeProfile;

    final groups = await ref.read(groupsControllerProvider.future);
    return groups.isEmpty
        ? AppDestination.emptyGroups
        : AppDestination.groupsDashboard;
  } on AppFailure catch (failure) {
    if (failure.type != AppFailureType.sessionExpired) rethrow;
    try {
      await auth.signOut();
    } on AuthFailure {
      // The session is already unusable; continue to login regardless.
    }
    return AppDestination.phoneLogin;
  }
}

/// Clears cached teacher data so the next read fetches it for the current
/// session.
final resetSessionDataProvider = Provider<void Function()>(
  (ref) => () {
    ref.invalidate(currentProfileProvider);
    ref.invalidate(groupsControllerProvider);
  },
);

/// Startup resolution displayed by the splash screen.
final appStartupProvider = FutureProvider.autoDispose<AppDestination>(
  resolveAppDestination,
);
