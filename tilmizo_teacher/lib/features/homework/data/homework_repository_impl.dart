import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/homework_repository.dart';
import 'homework_remote_data_source.dart';

final homeworkRemoteDataSourceProvider = Provider<HomeworkRemoteDataSource>(
  (ref) => SupabaseHomeworkDataSource(ref.watch(supabaseClientProvider)),
);

final homeworkRepositoryProvider = Provider<HomeworkRepository>(
  (ref) => HomeworkRepositoryImpl(
    ref.watch(homeworkRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class HomeworkRepositoryImpl implements HomeworkRepository {
  HomeworkRepositoryImpl(this._dataSource, this._auth);

  final HomeworkRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<List<Homework>> fetchGroupHomework(String groupId) =>
      _list(() => _dataSource.fetchHomework(groupId: groupId));

  @override
  Future<List<Homework>> fetchSessionHomework(String sessionId) =>
      _list(() => _dataSource.fetchHomework(sessionId: sessionId));

  @override
  Future<Homework?> fetchHomework(String homeworkId) async {
    final rows = await _list(
      () => _dataSource.fetchHomework(homeworkId: homeworkId),
    );
    return rows.firstOrNull;
  }

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
        // Keep the attachment order.
        return [for (final id in resourceIds) ?byId[id]];
      });

  @override
  Future<List<GroupResource>> fetchAttachableResources({
    required String groupId,
    required String sessionId,
  }) => _guard(() async {
    requireUserId(_auth);
    final rows = await _dataSource.fetchAttachableResources(
      groupId: groupId,
      sessionId: sessionId,
    );
    return [
      for (final resource in rows.map(GroupResource.fromRow))
        if (isAttachableResource(
          resource,
          groupId: groupId,
          sessionId: sessionId,
        ))
          resource,
    ];
  });

  @override
  Future<List<TeacherHomeworkSubmission>> fetchSubmissions(String homeworkId) =>
      _guard(() async {
        requireUserId(_auth);
        final rows = await _dataSource.fetchSubmissions(homeworkId);
        return [
          for (final row in rows)
            TeacherHomeworkSubmission(
              submission: HomeworkLinkSubmission.fromRow(row),
              studentName: switch (row['student']) {
                {'full_name': final String name} when name.trim().isNotEmpty =>
                  name.trim(),
                _ => null,
              },
            ),
        ];
      });

  @override
  Future<Homework> createHomework(HomeworkDraft draft) => _guard(() async {
    requireUserId(_auth);
    if (!draft.hasContent || draft.instructionsTooLong) {
      throw const HomeworkFailure(HomeworkFailureReason.invalidContent);
    }
    final row = await _dataSource.rpc('create_homework', {
      'p_session_id': draft.sessionId,
      'p_instructions': draft.trimmedInstructions,
      'p_submission_type': draft.submissionType.backendValue,
      'p_due_date': switch (draft.dueDate) {
        final date? => formatCalendarDate(date),
        null => null,
      },
      'p_resource_ids': draft.resourceIds.toSet().toList(),
    });
    return Homework.fromRow(Map<String, dynamic>.from(row! as Map));
  });

  @override
  Future<void> deleteHomework(String homeworkId) => _guard(() async {
    requireUserId(_auth);
    await _dataSource.rpc('delete_homework', {'p_homework_id': homeworkId});
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
    } on HomeworkFailure {
      rethrow;
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapHomeworkError(error);
    }
  }
}

/// Maps homework RPC rejections to a [HomeworkFailure] where the reason
/// helps the teacher, and everything else to a safe [AppFailure].
Exception mapHomeworkError(Object error) {
  if (error is HomeworkFailure) return error;
  if (error is AppFailure) return error;
  if (error is TypeError) return const AppFailure(AppFailureType.unknown);
  if (error is PostgrestException) {
    final message = error.message.toLowerCase();
    final reason = switch (error.code) {
      '42501' => HomeworkFailureReason.groupNotWritable,
      'P0002' => HomeworkFailureReason.notFound,
      '22023' when message.contains('session') =>
        HomeworkFailureReason.sessionCancelled,
      '22023' || '23514' || '23503' => HomeworkFailureReason.invalidContent,
      _ => null,
    };
    if (reason != null) return HomeworkFailure(reason);
  }
  return mapDataError(error);
}
