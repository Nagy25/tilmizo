import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_providers.dart';
import '../errors/network_errors.dart';

const profileAvatarBucket = 'profile-avatars';
const profileAvatarMaxBytes = 5 * 1024 * 1024;

enum ProfileAvatarFailureType {
  unsupportedFormat,
  tooLarge,
  unauthenticated,
  network,
  rejected,
  unknown,
}

final class ProfileAvatarFailure implements Exception {
  const ProfileAvatarFailure(this.type);

  final ProfileAvatarFailureType type;
}

final class PickedProfileAvatar {
  const PickedProfileAvatar({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

final class ProfileAvatarUpdate {
  const ProfileAvatarUpdate({
    required this.avatarPath,
    required this.updatedAt,
  });

  final String avatarPath;
  final DateTime updatedAt;
}

abstract interface class ProfileAvatarPicker {
  Future<PickedProfileAvatar?> pickFromGallery();
}

final class ImagePickerProfileAvatarPicker implements ProfileAvatarPicker {
  ImagePickerProfileAvatarPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedProfileAvatar?> pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (image == null) return null;

    return validateProfileAvatar(await image.readAsBytes());
  }
}

PickedProfileAvatar validateProfileAvatar(Uint8List bytes) {
  if (bytes.lengthInBytes > profileAvatarMaxBytes) {
    throw const ProfileAvatarFailure(ProfileAvatarFailureType.tooLarge);
  }

  final contentType = detectProfileAvatarContentType(bytes);
  if (contentType == null) {
    throw const ProfileAvatarFailure(
      ProfileAvatarFailureType.unsupportedFormat,
    );
  }
  return PickedProfileAvatar(bytes: bytes, contentType: contentType);
}

String? detectProfileAvatarContentType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

/// A one-pixel PNG is often a test placeholder; it is not a usable portrait.
bool isUsableProfileAvatarImage(Uint8List bytes) {
  if (detectProfileAvatarContentType(bytes) != 'image/png') return true;
  if (bytes.length < 24 ||
      bytes[12] != 0x49 ||
      bytes[13] != 0x48 ||
      bytes[14] != 0x44 ||
      bytes[15] != 0x52) {
    return false;
  }
  final data = ByteData.sublistView(bytes);
  return data.getUint32(16) >= 16 && data.getUint32(20) >= 16;
}

abstract interface class ProfileAvatarService {
  Future<ProfileAvatarUpdate> uploadOwnAvatar(PickedProfileAvatar avatar);

  Future<Uint8List> download(String path, {String? cacheNonce});
}

final class SupabaseProfileAvatarService implements ProfileAvatarService {
  SupabaseProfileAvatarService(this._client);

  final SupabaseClient _client;

  @override
  Future<ProfileAvatarUpdate> uploadOwnAvatar(
    PickedProfileAvatar avatar,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ProfileAvatarFailure(
        ProfileAvatarFailureType.unauthenticated,
      );
    }
    final path = '$userId/avatar';
    try {
      await _client.storage
          .from(profileAvatarBucket)
          .uploadBinary(
            path,
            avatar.bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: avatar.contentType,
              cacheControl: '0',
            ),
          );
      final response = await _client.rpc('set_my_profile_avatar');
      final data = Map<String, dynamic>.from(response as Map);
      return ProfileAvatarUpdate(
        avatarPath: data['avatar_path'] as String,
        updatedAt: DateTime.parse(data['updated_at'] as String),
      );
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<Uint8List> download(String path, {String? cacheNonce}) async {
    try {
      return await _client.storage
          .from(profileAvatarBucket)
          .download(path, cacheNonce: cacheNonce);
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  ProfileAvatarFailure _mapFailure(Object error) {
    if (error is ProfileAvatarFailure) return error;
    if (isNetworkError(error)) {
      return const ProfileAvatarFailure(ProfileAvatarFailureType.network);
    }
    if (error is AuthException) {
      return const ProfileAvatarFailure(
        ProfileAvatarFailureType.unauthenticated,
      );
    }
    if (error is StorageException) {
      return switch (error.statusCode) {
        '401' => const ProfileAvatarFailure(
          ProfileAvatarFailureType.unauthenticated,
        ),
        '403' ||
        '413' ||
        '415' => const ProfileAvatarFailure(ProfileAvatarFailureType.rejected),
        _ => const ProfileAvatarFailure(ProfileAvatarFailureType.unknown),
      };
    }
    if (error is PostgrestException) {
      return switch (error.code) {
        '401' || '42501' => const ProfileAvatarFailure(
          ProfileAvatarFailureType.unauthenticated,
        ),
        '22023' || '23514' => const ProfileAvatarFailure(
          ProfileAvatarFailureType.rejected,
        ),
        _ => const ProfileAvatarFailure(ProfileAvatarFailureType.unknown),
      };
    }
    return const ProfileAvatarFailure(ProfileAvatarFailureType.unknown);
  }
}

final profileAvatarPickerProvider = Provider<ProfileAvatarPicker>(
  (ref) => ImagePickerProfileAvatarPicker(),
);

final profileAvatarServiceProvider = Provider<ProfileAvatarService>(
  (ref) => SupabaseProfileAvatarService(ref.watch(supabaseClientProvider)),
);

typedef ProfileAvatarImageRequest = ({String path, String? revision});

final profileAvatarBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, ProfileAvatarImageRequest>((ref, request) {
      return ref
          .watch(profileAvatarServiceProvider)
          .download(request.path, cacheNonce: request.revision);
    });
