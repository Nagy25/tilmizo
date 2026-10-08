import 'package:core_package/core_package.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SELECT access to homework tables and the teacher homework RPCs. The
/// client never writes homework tables directly.
abstract interface class HomeworkRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchHomework({
    String? groupId,
    String? sessionId,
    String? homeworkId,
  });

  Future<List<Map<String, dynamic>>> fetchResources(List<String> ids);

  Future<List<Map<String, dynamic>>> fetchAttachableResources({
    required String groupId,
    required String sessionId,
  });

  Future<List<Map<String, dynamic>>> fetchSubmissions(String homeworkId);

  Future<Object?> rpc(String function, Map<String, dynamic> params);
}

final class SupabaseHomeworkDataSource implements HomeworkRemoteDataSource {
  SupabaseHomeworkDataSource(this._client);

  /// PostgREST's default maximum page; a group never approaches it.
  static const _maxRows = 1000;

  /// Submissions with the student's name through the `student_id` key.
  static const submissionColumns =
      '${HomeworkLinkSubmission.columns}, '
      'student:profiles!homework_link_submissions_student_id_fkey(full_name)';

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchHomework({
    String? groupId,
    String? sessionId,
    String? homeworkId,
  }) {
    var query = _client.from('homework').select(Homework.listColumns);
    if (groupId != null) query = query.eq('group_id', groupId);
    if (sessionId != null) query = query.eq('session_id', sessionId);
    if (homeworkId != null) query = query.eq('id', homeworkId);
    return query
        .order('created_at', ascending: false)
        .order('id')
        .limit(_maxRows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchResources(List<String> ids) => _client
      .from('resources')
      .select(GroupResource.columns)
      .inFilter('id', ids);

  @override
  Future<List<Map<String, dynamic>>> fetchAttachableResources({
    required String groupId,
    required String sessionId,
  }) => _client
      .from('resources')
      .select(GroupResource.columns)
      .eq('group_id', groupId)
      .not('storage_path', 'is', null)
      .or('session_id.is.null,session_id.eq.$sessionId')
      .order('created_at', ascending: false)
      .limit(_maxRows);

  @override
  Future<List<Map<String, dynamic>>> fetchSubmissions(String homeworkId) =>
      _client
          .from('homework_link_submissions')
          .select(submissionColumns)
          .eq('homework_id', homeworkId)
          .order('updated_at', ascending: false)
          .limit(_maxRows);

  @override
  Future<Object?> rpc(String function, Map<String, dynamic> params) async =>
      await _client.rpc(function, params: params);
}
