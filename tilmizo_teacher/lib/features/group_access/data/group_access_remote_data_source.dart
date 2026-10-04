import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'group_access_dto.dart';

/// Raw access to the Phase 2 tables and workflow RPCs.
abstract interface class GroupAccessRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchPendingRequests({
    required String teacherId,
    required String groupId,
  });

  Future<Map<String, dynamic>?> fetchRequest({
    required String teacherId,
    required String requestId,
  });

  Future<List<Map<String, dynamic>>> fetchMembers({
    required String teacherId,
    required String groupId,
  });

  Future<Map<String, dynamic>?> fetchMember({
    required String teacherId,
    required String membershipId,
  });

  Future<Map<String, dynamic>> decideRequest(Map<String, dynamic> params);

  Future<void> revokeMemberAccess(Map<String, dynamic> params);

  Stream<void> watchGroup(String groupId);
}

final class SupabaseGroupAccessDataSource
    implements GroupAccessRemoteDataSource {
  SupabaseGroupAccessDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchPendingRequests({
    required String teacherId,
    required String groupId,
  }) {
    return _client
        .from('group_join_requests')
        .select(GroupAccessDto.requestColumns)
        .eq('owner.teacher_id', teacherId)
        .eq('group_id', groupId)
        .eq('status', JoinRequestStatus.pending.backendValue)
        .order('created_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchRequest({
    required String teacherId,
    required String requestId,
  }) {
    return _client
        .from('group_join_requests')
        .select(GroupAccessDto.requestColumns)
        .eq('owner.teacher_id', teacherId)
        .eq('id', requestId)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMembers({
    required String teacherId,
    required String groupId,
  }) {
    return _client
        .from('group_memberships')
        .select(GroupAccessDto.memberColumns)
        .eq('owner.teacher_id', teacherId)
        .eq('group_id', groupId)
        .inFilter('status', [
          MembershipStatus.active.backendValue,
          MembershipStatus.suspended.backendValue,
        ])
        .order('updated_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchMember({
    required String teacherId,
    required String membershipId,
  }) {
    return _client
        .from('group_memberships')
        .select(GroupAccessDto.memberColumns)
        .eq('owner.teacher_id', teacherId)
        .eq('id', membershipId)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> decideRequest(
    Map<String, dynamic> params,
  ) async {
    final result = await _client.rpc<dynamic>(
      'decide_group_access_request',
      params: params,
    );
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<void> revokeMemberAccess(Map<String, dynamic> params) =>
      _client.rpc<void>('revoke_group_member_access', params: params);

  @override
  Stream<void> watchGroup(String groupId) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'group_id',
      value: groupId,
    );

    controller = StreamController<void>(
      onListen: () {
        channel = _client
            .channel('teacher-group-access-$groupId')
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
}
