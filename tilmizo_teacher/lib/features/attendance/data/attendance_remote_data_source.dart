import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AttendanceRemoteDataSource {
  /// One page of the group's memberships in every status, ordered by id.
  Future<List<Map<String, dynamic>>> fetchMembershipPage({
    required String teacherId,
    required String groupId,
    required int limit,
    String? afterId,
  });

  Future<List<Map<String, dynamic>>> fetchAttendance(String sessionId);

  Future<Map<String, dynamic>> setAttendance({
    required String sessionId,
    required String studentId,
    required String status,
  });
}

final class SupabaseAttendanceDataSource implements AttendanceRemoteDataSource {
  SupabaseAttendanceDataSource(this._client);

  final SupabaseClient _client;

  static const _memberColumns =
      'id, student_id, status, '
      'student:profiles!group_memberships_student_id_fkey(full_name, phone), '
      'owner:groups!inner(teacher_id)';

  @override
  Future<List<Map<String, dynamic>>> fetchMembershipPage({
    required String teacherId,
    required String groupId,
    required int limit,
    String? afterId,
  }) {
    var query = _client
        .from('group_memberships')
        .select(_memberColumns)
        .eq('owner.teacher_id', teacherId)
        .eq('group_id', groupId);
    if (afterId != null) query = query.gt('id', afterId);
    return query.order('id', ascending: true).limit(limit);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttendance(String sessionId) {
    return _client
        .from('session_attendance')
        .select('student_id, status')
        .eq('session_id', sessionId);
  }

  @override
  Future<Map<String, dynamic>> setAttendance({
    required String sessionId,
    required String studentId,
    required String status,
  }) async => await _client.rpc(
    'set_session_attendance',
    params: {
      'p_session_id': sessionId,
      'p_student_id': studentId,
      'p_status': status,
    },
  );
}
