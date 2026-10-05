import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class TeacherStudentsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchPage({
    required String teacherId,
    required int limit,
    String? afterId,
  });
}

final class SupabaseTeacherStudentsDataSource
    implements TeacherStudentsRemoteDataSource {
  SupabaseTeacherStudentsDataSource(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, student_id, status, joined_at, '
      'student:profiles!group_memberships_student_id_fkey(full_name, phone), '
      'owner:groups!inner(id, name, teacher_id)';

  @override
  Future<List<Map<String, dynamic>>> fetchPage({
    required String teacherId,
    required int limit,
    String? afterId,
  }) {
    var query = _client
        .from('group_memberships')
        .select(_columns)
        .eq('owner.teacher_id', teacherId)
        .inFilter('status', ['active', 'suspended']);
    if (afterId != null) query = query.gt('id', afterId);
    return query.order('id').limit(limit);
  }
}
