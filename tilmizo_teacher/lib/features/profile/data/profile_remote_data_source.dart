import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_dto.dart';

/// Raw row access to `public.profiles`.
abstract interface class ProfileRemoteDataSource {
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  Future<Map<String, dynamic>?> updateProfile(
    String userId,
    Map<String, dynamic> payload,
  );
}

final class SupabaseProfileDataSource implements ProfileRemoteDataSource {
  SupabaseProfileDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) {
    return _client
        .from('profiles')
        .select(ProfileDto.columns)
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> updateProfile(
    String userId,
    Map<String, dynamic> payload,
  ) {
    return _client
        .from('profiles')
        .update(payload)
        .eq('id', userId)
        .select(ProfileDto.columns)
        .maybeSingle();
  }
}
