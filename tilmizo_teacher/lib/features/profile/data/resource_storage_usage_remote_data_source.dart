import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ResourceStorageUsageRemoteDataSource {
  Future<Map<String, dynamic>> fetchOwnUsage();
}

final class SupabaseResourceStorageUsageDataSource
    implements ResourceStorageUsageRemoteDataSource {
  SupabaseResourceStorageUsageDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> fetchOwnUsage() async {
    final response = await _client.rpc('get_my_resource_storage_usage');
    return Map<String, dynamic>.from(response as Map);
  }
}
