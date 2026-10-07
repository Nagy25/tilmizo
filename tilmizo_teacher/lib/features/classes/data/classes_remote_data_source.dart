import 'package:core_package/core_package.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/classes_repository.dart';
import 'classes_dto.dart';

/// Raw row access to sessions and weekly schedules. Reads are filtered by
/// owner; writes rely on row-level security for ownership.
abstract interface class ClassesRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchSessions({
    required String teacherId,
    required SessionsView view,
    required DateTime now,
    required int offset,
    required int limit,
    String? groupId,
  });

  Future<Map<String, dynamic>?> fetchSession(String teacherId, String id);

  /// Calls `create_manual_class_session` and returns the new session row.
  Future<Map<String, dynamic>> createManualSession(Map<String, dynamic> params);

  /// Calls `create_manual_session_with_payment`, which creates the session
  /// and its payment amount in one transaction, and returns the new session
  /// row.
  Future<Map<String, dynamic>> createManualSessionWithPayment(
    Map<String, dynamic> params,
  );

  /// Updates only teacher-writable session columns.
  Future<Map<String, dynamic>?> updateSession(
    String id,
    Map<String, dynamic> payload,
  );

  Future<List<Map<String, dynamic>>> fetchActiveEntries(
    String teacherId,
    String groupId,
  );

  Future<Map<String, dynamic>?> fetchEntry(String teacherId, String id);

  Future<void> insertEntries(List<Map<String, dynamic>> rows);

  Future<Map<String, dynamic>?> updateEntry(
    String id,
    Map<String, dynamic> payload,
  );
}

final class SupabaseClassesDataSource implements ClassesRemoteDataSource {
  SupabaseClassesDataSource(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _sessions => _client.from('class_sessions');
  SupabaseQueryBuilder get _entries => _client.from('group_schedule_entries');

  @override
  Future<List<Map<String, dynamic>>> fetchSessions({
    required String teacherId,
    required SessionsView view,
    required DateTime now,
    required int offset,
    required int limit,
    String? groupId,
  }) {
    final instant = now.toUtc().toIso8601String();
    var query = _sessions
        .select(ClassesDto.sessionColumns)
        .eq('group.teacher_id', teacherId);
    if (groupId != null) query = query.eq('group_id', groupId);
    final ordered = switch (view) {
      SessionsView.upcoming =>
        query
            .eq('status', SessionStatus.scheduled.backendValue)
            .gt('ends_at', instant)
            .order('starts_at', ascending: true),
      SessionsView.past =>
        query
            .neq('status', SessionStatus.cancelled.backendValue)
            .or('ends_at.lte."$instant",status.eq.completed')
            .order('starts_at', ascending: false),
      SessionsView.cancelled =>
        query
            .eq('status', SessionStatus.cancelled.backendValue)
            .order('starts_at', ascending: false),
    };
    return ordered
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);
  }

  @override
  Future<Map<String, dynamic>?> fetchSession(String teacherId, String id) {
    return _sessions
        .select(ClassesDto.sessionColumns)
        .eq('group.teacher_id', teacherId)
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> createManualSession(
    Map<String, dynamic> params,
  ) async => await _client.rpc('create_manual_class_session', params: params);

  @override
  Future<Map<String, dynamic>> createManualSessionWithPayment(
    Map<String, dynamic> params,
  ) async {
    final result = await _client.rpc(
      'create_manual_session_with_payment',
      params: params,
    );
    return Map<String, dynamic>.from((result as Map)['session'] as Map);
  }

  @override
  Future<Map<String, dynamic>?> updateSession(
    String id,
    Map<String, dynamic> payload,
  ) {
    return _sessions
        .update(payload)
        .eq('id', id)
        .select(ClassesDto.sessionColumns)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveEntries(
    String teacherId,
    String groupId,
  ) {
    return _entries
        .select(ClassesDto.entryColumns)
        .eq('owner.teacher_id', teacherId)
        .eq('group_id', groupId)
        .eq('is_active', true)
        .order('weekday', ascending: true)
        .order('start_time', ascending: true);
  }

  @override
  Future<Map<String, dynamic>?> fetchEntry(String teacherId, String id) {
    return _entries
        .select(ClassesDto.entryColumns)
        .eq('owner.teacher_id', teacherId)
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<void> insertEntries(List<Map<String, dynamic>> rows) =>
      _entries.insert(rows);

  @override
  Future<Map<String, dynamic>?> updateEntry(
    String id,
    Map<String, dynamic> payload,
  ) {
    return _entries
        .update(payload)
        .eq('id', id)
        .select(ClassesDto.entryColumns)
        .maybeSingle();
  }
}
