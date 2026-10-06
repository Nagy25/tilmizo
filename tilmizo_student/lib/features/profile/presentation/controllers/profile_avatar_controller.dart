import 'package:core_package/core_package.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_profile_controller.dart';

@immutable
final class ProfileAvatarState {
  const ProfileAvatarState({this.isUpdating = false, this.failure});

  final bool isUpdating;
  final ProfileAvatarFailureType? failure;
}

final profileAvatarControllerProvider =
    NotifierProvider.autoDispose<ProfileAvatarController, ProfileAvatarState>(
      ProfileAvatarController.new,
    );

class ProfileAvatarController extends Notifier<ProfileAvatarState> {
  @override
  ProfileAvatarState build() => const ProfileAvatarState();

  Future<bool> pickAndUpload() async {
    if (state.isUpdating) return false;
    state = const ProfileAvatarState(isUpdating: true);
    try {
      final avatar = await ref
          .read(profileAvatarPickerProvider)
          .pickFromGallery();
      if (avatar == null) {
        if (ref.mounted) state = const ProfileAvatarState();
        return false;
      }
      await ref.read(profileAvatarServiceProvider).uploadOwnAvatar(avatar);
      ref.invalidate(currentProfileProvider);
      await ref.read(currentProfileProvider.future);
      if (ref.mounted) state = const ProfileAvatarState();
      return true;
    } on ProfileAvatarFailure catch (failure) {
      if (ref.mounted) state = ProfileAvatarState(failure: failure.type);
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = const ProfileAvatarState(
          failure: ProfileAvatarFailureType.unknown,
        );
      }
      return false;
    }
  }
}
