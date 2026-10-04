import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'group_access_dto.dart';

abstract interface class GroupAccessRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchOverview();

  Future<Map<String, dynamic>> requestAccess(Map<String, dynamic> params);

  Future<Map<String, dynamic>> requestDeviceReplacement(
    Map<String, dynamic> params,
  );

  Future<void> leaveGroup(Map<String, dynamic> params);

  Future<Map<String, dynamic>?> fetchGroup(String groupId);

  Stream<void> watchStudent(String studentId);
}

final class SupabaseGroupAccessDataSource
    implements GroupAccessRemoteDataSource {
  SupabaseGroupAccessDataSource(this._client);

  final SupabaseClient _client;

  /// The RPC returns a JSON array of safe per-group summaries.
  @override
  Future<List<Map<String, dynamic>>> fetchOverview() async {
    final rows = await _client.rpc<dynamic>('get_my_group_access_overview');
    return [
      for (final row in rows as List) Map<String, dynamic>.from(row as Map),
    ];
  }

  @override
  Future<Map<String, dynamic>> requestAccess(Map<String, dynamic> params) =>
      _rpcObject('request_group_access', params);

  @override
  Future<Map<String, dynamic>> requestDeviceReplacement(
    Map<String, dynamic> params,
  ) => _rpcObject('request_group_device_replacement', params);

  @override
  Future<void> leaveGroup(Map<String, dynamic> params) =>
      _client.rpc<void>('leave_group', params: params);

  /// Subject to the session-bound groups RLS: returns null unless this is
  /// the approved session.
  @override
  Future<Map<String, dynamic>?> fetchGroup(String groupId) {
    return _client
        .from('groups')
        .select(GroupAccessDto.approvedGroupColumns)
        .eq('id', groupId)
        .maybeSingle();
  }

  @override
  Stream<void> watchStudent(String studentId) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'student_id',
      value: studentId,
    );

    controller = StreamController<void>(
      onListen: () {
        channel = _client
            .channel('student-group-access-$studentId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'group_join_requests',
              filter: filter,
              callback: (_) => controller.add(null),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'group_memberships',
              filter: filter,
              callback: (_) => controller.add(null),
            )
            .subscribe();
      },
      onCancel: () async {
        final active = channel;
        channel = null;
        if (active != null) await _client.removeChannel(active);
      },
    );
    return controller.stream;
  }

  Future<Map<String, dynamic>> _rpcObject(
    String function,
    Map<String, dynamic> params,
  ) async {
    final result = await _client.rpc<dynamic>(function, params: params);
    return Map<String, dynamic>.from(result as Map);
  }
}
