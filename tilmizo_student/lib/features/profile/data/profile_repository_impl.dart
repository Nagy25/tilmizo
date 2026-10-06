import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_repository.dart';
import '../domain/student_profile.dart';
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
  Future<StudentProfile> fetchOwnProfile() => _guard(() async {
    final row = await _dataSource.fetchProfile(requireUserId(_auth));
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    return profileFromRow(row);
  });

  @override
  Future<StudentProfile> updateFullName(String fullName) => _guard(() async {
    final name = trimToNull(fullName);
    if (name == null) throw const AppFailure(AppFailureType.invalidInput);
    final row = await _dataSource.updateProfile(
      requireUserId(_auth),
      updatePayload(name),
    );
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    return profileFromRow(row);
  });

  /// Only `full_name` is sent; ID, phone, and timestamps are never written.
  static Map<String, dynamic> updatePayload(String fullName) => {
    'full_name': fullName,
  };

  static StudentProfile profileFromRow(Map<String, dynamic> row) =>
      StudentProfile(
        id: row['id'] as String,
        fullName: row['full_name'] as String?,
        phone: row['phone'] as String,
        avatarUrl: row['avatar_url'] as String?,
        updatedAt: switch (row['updated_at']) {
          final String value => DateTime.parse(value),
          _ => null,
        },
      );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
