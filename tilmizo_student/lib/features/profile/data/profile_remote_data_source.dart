import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProfileRemoteDataSource {
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  Future<Map<String, dynamic>?> updateProfile(
    String userId,
    Map<String, dynamic> payload,
  );
}

final class SupabaseProfileDataSource implements ProfileRemoteDataSource {
  SupabaseProfileDataSource(this._client);

  static const columns = 'id, full_name, phone, avatar_url';

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) =>
      _client.from('profiles').select(columns).eq('id', userId).maybeSingle();

  @override
  Future<Map<String, dynamic>?> updateProfile(
    String userId,
    Map<String, dynamic> payload,
  ) => _client
      .from('profiles')
      .update(payload)
      .eq('id', userId)
      .select(columns)
      .maybeSingle();
}
