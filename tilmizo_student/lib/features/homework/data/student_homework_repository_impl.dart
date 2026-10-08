import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/student_homework_repository.dart';

abstract interface class StudentHomeworkRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchHomework({
    String? groupId,
    String? sessionId,
    String? homeworkId,
  });

  Future<List<Map<String, dynamic>>> fetchResources(List<String> ids);

  Future<Map<String, dynamic>?> fetchSubmission({
    required String homeworkId,
    required String studentId,
  });

  Future<Object?> submitLink(String homeworkId, String url);
}

/// SELECT queries plus `submit_homework_link`; students never write
/// homework or Resources.
final class SupabaseStudentHomeworkDataSource
    implements StudentHomeworkRemoteDataSource {
  SupabaseStudentHomeworkDataSource(this._client);

  static const _maxRows = 1000;

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
  Future<Map<String, dynamic>?> fetchSubmission({
    required String homeworkId,
    required String studentId,
  }) => _client
      .from('homework_link_submissions')
      .select(HomeworkLinkSubmission.columns)
      .eq('homework_id', homeworkId)
      .eq('student_id', studentId)
      .maybeSingle();

  @override
  Future<Object?> submitLink(String homeworkId, String url) async =>
      await _client.rpc(
        'submit_homework_link',
        params: {'p_homework_id': homeworkId, 'p_url': url},
      );
}

final studentHomeworkRemoteDataSourceProvider =
    Provider<StudentHomeworkRemoteDataSource>(
      (ref) =>
          SupabaseStudentHomeworkDataSource(ref.watch(supabaseClientProvider)),
    );

final studentHomeworkRepositoryProvider = Provider<StudentHomeworkRepository>(
  (ref) => StudentHomeworkRepositoryImpl(
    ref.watch(studentHomeworkRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class StudentHomeworkRepositoryImpl implements StudentHomeworkRepository {
  StudentHomeworkRepositoryImpl(this._dataSource, this._auth);

  final StudentHomeworkRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<List<Homework>> fetchGroupHomework(String groupId) =>
      _list(() => _dataSource.fetchHomework(groupId: groupId));

  @override
  Future<List<Homework>> fetchSessionHomework(String sessionId) =>
      _list(() => _dataSource.fetchHomework(sessionId: sessionId));

  @override
  Future<Homework?> fetchHomework(String homeworkId) async =>
      (await _list(() => _dataSource.fetchHomework(homeworkId: homeworkId)))
          .firstOrNull;

  @override
  Future<List<GroupResource>> fetchResources(List<String> resourceIds) =>
      _guard(() async {
        requireUserId(_auth);
        if (resourceIds.isEmpty) return const [];
        final rows = await _dataSource.fetchResources(resourceIds);
        final byId = {
          for (final resource in rows.map(GroupResource.fromRow))
            resource.id: resource,
        };
        return [
          for (final id in resourceIds)
            // Attachments are uploads; never offer a link as a download.
            if (byId[id] case final resource? when resource.type.isUpload)
              resource,
        ];
      });

  @override
  Future<HomeworkLinkSubmission?> fetchMySubmission(String homeworkId) =>
      _guard(() async {
        final studentId = requireUserId(_auth);
        final row = await _dataSource.fetchSubmission(
          homeworkId: homeworkId,
          studentId: studentId,
        );
        final submission = row == null
            ? null
            : HomeworkLinkSubmission.fromRow(row);
        // Defence in depth: never show another student's link.
        return submission?.studentId == studentId ? submission : null;
      });

  @override
  Future<HomeworkLinkSubmission> submitLink(String homeworkId, String url) =>
      _guard(() async {
        requireUserId(_auth);
        final link = url.trim();
        if (!isValidHomeworkLink(link)) {
          throw const AppFailure(AppFailureType.invalidInput);
        }
        final row = await _dataSource.submitLink(homeworkId, link);
        return HomeworkLinkSubmission.fromRow(
          Map<String, dynamic>.from(row! as Map),
        );
      });

  Future<List<Homework>> _list(
    Future<List<Map<String, dynamic>>> Function() fetch,
  ) => _guard(() async {
    requireUserId(_auth);
    final rows = await fetch();
    return rows.map(Homework.fromRow).toList(growable: false);
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      if (error is TypeError) throw const AppFailure(AppFailureType.unknown);
      // `submit_homework_link` uses 42501 both after the Cairo cutoff and
      // when this session is no longer approved; callers re-check access.
      if (error is PostgrestException && error.code == '42501') {
        throw const AppFailure(AppFailureType.notEligible);
      }
      throw mapDataError(error);
    }
  }
}
