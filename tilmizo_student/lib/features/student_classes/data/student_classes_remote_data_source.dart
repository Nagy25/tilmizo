import 'package:core_package/core_package.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/student_class.dart';
import 'student_classes_dto.dart';

abstract interface class StudentClassesRemoteDataSource {
  Future<({List<Map<String, dynamic>> rows, int? total})> fetchSessions({
    required List<String> groupIds,
    required StudentSessionsView view,
    required DateTime now,
    required int offset,
    required int limit,
    String? groupId,
  });

  Future<Map<String, dynamic>?> fetchSession(String id, List<String> groupIds);
  Future<List<Map<String, dynamic>>> fetchAttendance(
    String studentId,
    List<String> sessionIds,
  );
  Future<List<Map<String, dynamic>>> fetchSchedule(String groupId);
  Future<List<Map<String, dynamic>>> fetchGroupActivity(List<String> groupIds);
}

final class SupabaseStudentClassesDataSource
    implements StudentClassesRemoteDataSource {
  SupabaseStudentClassesDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<({List<Map<String, dynamic>> rows, int? total})> fetchSessions({
    required List<String> groupIds,
    required StudentSessionsView view,
    required DateTime now,
    required int offset,
    required int limit,
    String? groupId,
  }) async {
    final instant = now.toUtc().toIso8601String();
    var query = _client
        .from('class_sessions')
        .select(StudentClassesDto.sessionColumns)
        .inFilter('group_id', groupIds);
    if (groupId != null) query = query.eq('group_id', groupId);
    final ordered = switch (view) {
      StudentSessionsView.upcoming =>
        query
            .eq('status', SessionStatus.scheduled.backendValue)
            .gt('ends_at', instant)
            .order('starts_at'),
      StudentSessionsView.past =>
        query
            .neq('status', SessionStatus.cancelled.backendValue)
            .or('ends_at.lte."$instant",status.eq.completed')
            .order('starts_at', ascending: false),
      StudentSessionsView.cancelled =>
        query
            .eq('status', SessionStatus.cancelled.backendValue)
            .order('starts_at', ascending: false),
    };
    final response = await ordered
        .order('id')
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);
    return (rows: response.data, total: response.count);
  }

  @override
  Future<Map<String, dynamic>?> fetchSession(
    String id,
    List<String> groupIds,
  ) => _client
      .from('class_sessions')
      .select(StudentClassesDto.sessionColumns)
      .eq('id', id)
      .inFilter('group_id', groupIds)
      .maybeSingle();

  @override
  Future<List<Map<String, dynamic>>> fetchAttendance(
    String studentId,
    List<String> sessionIds,
  ) => _client
      .from('session_attendance')
      .select('session_id,status')
      .eq('student_id', studentId)
      .inFilter('session_id', sessionIds);

  @override
  Future<List<Map<String, dynamic>>> fetchSchedule(String groupId) => _client
      .from('group_schedule_entries')
      .select(StudentClassesDto.scheduleColumns)
      .eq('group_id', groupId)
      .eq('is_active', true)
      .order('weekday')
      .order('start_time');

  @override
  Future<List<Map<String, dynamic>>> fetchGroupActivity(
    List<String> groupIds,
  ) => _client.from('groups').select('id,is_active').inFilter('id', groupIds);
}
