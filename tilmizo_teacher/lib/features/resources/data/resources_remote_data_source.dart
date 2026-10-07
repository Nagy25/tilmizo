import 'package:core_package/core_package.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ResourcesRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchResources(
    String groupId, {
    required int offset,
    required int limit,
  });

  Future<Map<String, dynamic>?> fetchResource(String resourceId);

  Future<List<Map<String, dynamic>>> fetchTypes(String groupId);

  Future<List<Map<String, dynamic>>> fetchSessions(String groupId);

  Future<Map<String, dynamic>> callRpc(
    String function,
    Map<String, dynamic> params,
  );

  /// Invokes an authenticated Edge Function. Non-2xx responses throw
  /// [FunctionException] with the `{error}` body in `details`.
  Future<({int status, Map<String, dynamic> body})> invokeFunction(
    String function,
    Map<String, dynamic> body,
  );
}

final class SupabaseResourcesDataSource implements ResourcesRemoteDataSource {
  SupabaseResourcesDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchResources(
    String groupId, {
    required int offset,
    required int limit,
  }) => _client
      .from('resources')
      .select(GroupResource.columns)
      .eq('group_id', groupId)
      .order('created_at', ascending: false)
      .order('id')
      .range(offset, offset + limit - 1);

  @override
  Future<Map<String, dynamic>?> fetchResource(String resourceId) => _client
      .from('resources')
      .select(GroupResource.columns)
      .eq('id', resourceId)
      .maybeSingle();

  @override
  Future<List<Map<String, dynamic>>> fetchTypes(String groupId) =>
      _client.from('resources').select('type').eq('group_id', groupId);

  @override
  Future<List<Map<String, dynamic>>> fetchSessions(String groupId) => _client
      .from('class_sessions')
      .select(ResourceSessionOption.columns)
      .eq('group_id', groupId)
      .order('starts_at', ascending: false);

  @override
  Future<Map<String, dynamic>> callRpc(
    String function,
    Map<String, dynamic> params,
  ) async {
    final response = await _client.rpc(function, params: params);
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<({int status, Map<String, dynamic> body})> invokeFunction(
    String function,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.functions.invoke(function, body: body);
    final data = response.data;
    return (
      status: response.status,
      body: data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
    );
  }
}
