import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_repository_impl.dart';
import '../../domain/student_profile.dart';

final currentProfileProvider =
    AsyncNotifierProvider<CurrentProfileController, StudentProfile>(
      CurrentProfileController.new,
    );

class CurrentProfileController extends AsyncNotifier<StudentProfile> {
  @override
  Future<StudentProfile> build() =>
      ref.watch(profileRepositoryProvider).fetchOwnProfile();

  Future<StudentProfile> saveName(String fullName) async {
    final saved = await ref
        .read(profileRepositoryProvider)
        .updateFullName(fullName);
    state = AsyncData(saved);
    return saved;
  }
}
