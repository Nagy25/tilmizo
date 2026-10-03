import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/supabase_profile_repository.dart';
import '../../domain/profile_update.dart';
import '../../domain/teacher_profile.dart';

/// The authenticated teacher's profile, shared by every screen.
final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfileController, TeacherProfile>(
      CurrentProfileController.new,
    );

class CurrentProfileController extends AsyncNotifier<TeacherProfile> {
  @override
  Future<TeacherProfile> build() =>
      ref.watch(profileRepositoryProvider).fetchOwnProfile();

  Future<TeacherProfile> save(ProfileUpdate update) async {
    final saved = await ref
        .read(profileRepositoryProvider)
        .updateOwnProfile(update);
    state = AsyncData(saved);
    return saved;
  }
}
