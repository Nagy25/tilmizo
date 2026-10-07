import 'package:supabase_flutter/supabase_flutter.dart';

import 'group_dto.dart';

/// Raw row access to `public.groups`, always filtered by owner.
abstract interface class GroupsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchGroups(String teacherId);

  Future<Map<String, dynamic>?> fetchGroup(String teacherId, String groupId);

  Future<Map<String, dynamic>> insertGroup(Map<String, dynamic> payload);

  Future<Map<String, dynamic>?> updateGroup(
    String teacherId,
    String groupId,
    Map<String, dynamic> payload,
  );

  Future<Map<String, dynamic>> archiveGroup(String groupId);

  Future<Map<String, dynamic>> setSuspension(String groupId, bool suspended);
}

final class SupabaseGroupsDataSource implements GroupsRemoteDataSource {
  SupabaseGroupsDataSource(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _groups => _client.from('groups');

  @override
  Future<List<Map<String, dynamic>>> fetchGroups(String teacherId) {
    return _groups
        .select(GroupDto.columns)
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchGroup(String teacherId, String groupId) {
    return _groups
        .select(GroupDto.columns)
        .eq('teacher_id', teacherId)
        .eq('id', groupId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> insertGroup(Map<String, dynamic> payload) {
    return _groups.insert(payload).select(GroupDto.columns).single();
  }

  @override
  Future<Map<String, dynamic>?> updateGroup(
    String teacherId,
    String groupId,
    Map<String, dynamic> payload,
  ) {
    return _groups
        .update(payload)
        .eq('teacher_id', teacherId)
        .eq('id', groupId)
        .select(GroupDto.columns)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> archiveGroup(String groupId) async =>
      await _client.rpc('archive_group', params: {'p_group_id': groupId});

  @override
  Future<Map<String, dynamic>> setSuspension(
    String groupId,
    bool suspended,
  ) async => await _client.rpc(
    'set_group_suspension',
    params: {'p_group_id': groupId, 'p_suspended': suspended},
  );
}
