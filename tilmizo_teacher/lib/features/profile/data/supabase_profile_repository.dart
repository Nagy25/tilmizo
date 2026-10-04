import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_repository.dart';
import '../domain/profile_update.dart';
import '../domain/teacher_profile.dart';
import 'profile_dto.dart';
import 'profile_remote_data_source.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => SupabaseProfileDataSource(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ref.watch(profileRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._dataSource, this._auth);

  final ProfileRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<TeacherProfile> fetchOwnProfile() async {
    try {
      final row = await _dataSource.fetchProfile(requireUserId(_auth));
      if (row == null) throw const AppFailure(AppFailureType.notFound);
      return ProfileDto.fromRow(row);
    } catch (error) {
      throw mapDataError(error);
    }
  }

  @override
  Future<TeacherProfile> updateOwnProfile(ProfileUpdate update) async {
    try {
      final row = await _dataSource.updateProfile(
        requireUserId(_auth),
        ProfileDto.toUpdatePayload(update),
      );
      if (row == null) throw const AppFailure(AppFailureType.notFound);
      return ProfileDto.fromRow(row);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
