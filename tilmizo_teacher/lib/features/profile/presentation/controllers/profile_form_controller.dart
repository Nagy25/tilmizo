import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/profile_update.dart';
import '../../domain/teacher_profile.dart';
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

  /// Saves the permitted profile fields. Returns the saved profile, or `null`
  /// when validation or the request fails.
  Future<TeacherProfile?> submit({
    required String fullName,
    required String teachingSubject,
  }) async {
    if (state.isSaving) return null;
    final update = ProfileUpdate.tryCreate(
      fullName: fullName,
      teachingSubject: teachingSubject,
    );
    if (update == null) return null;

    state = const ProfileFormState(isSaving: true);
    try {
      final saved = await ref
          .read(currentProfileProvider.notifier)
          .save(update);
      if (ref.mounted) state = const ProfileFormState();
      return saved;
    } on AppFailure catch (failure) {
      if (ref.mounted) state = ProfileFormState(failure: failure.type);
      return null;
    }
  }
}
