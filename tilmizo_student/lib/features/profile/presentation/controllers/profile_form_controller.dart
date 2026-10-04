import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/student_profile.dart';
import 'current_profile_controller.dart';

@immutable
final class ProfileFormState {
  const ProfileFormState({this.isSaving = false, this.failure});

  final bool isSaving;
  final AppFailureType? failure;
}

final profileFormControllerProvider =
    NotifierProvider.autoDispose<ProfileFormController, ProfileFormState>(
      ProfileFormController.new,
    );

class ProfileFormController extends Notifier<ProfileFormState> {
  @override
  ProfileFormState build() => const ProfileFormState();

  /// Saves the name. Returns `null` when blank, already saving, or failed.
  Future<StudentProfile?> submit(String fullName) async {
    if (state.isSaving || trimToNull(fullName) == null) return null;
    state = const ProfileFormState(isSaving: true);
    try {
      final saved = await ref
          .read(currentProfileProvider.notifier)
          .saveName(fullName);
      if (ref.mounted) state = const ProfileFormState();
      return saved;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = ProfileFormState(failure: failure.type);
      return null;
    }
  }
}
