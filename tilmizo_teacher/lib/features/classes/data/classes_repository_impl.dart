import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/class_session.dart';
import '../domain/classes_repository.dart';
import '../domain/one_time_session_draft.dart';
import '../domain/schedule_entry.dart';
import '../domain/session_location.dart';
import 'classes_dto.dart';
import 'classes_remote_data_source.dart';

final classesRemoteDataSourceProvider = Provider<ClassesRemoteDataSource>(
  (ref) => SupabaseClassesDataSource(ref.watch(supabaseClientProvider)),
);

final classesRepositoryProvider = Provider<ClassesRepository>(
  (ref) => ClassesRepositoryImpl(
    ref.watch(classesRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class ClassesRepositoryImpl implements ClassesRepository {
  ClassesRepositoryImpl(this._dataSource, this._auth);

  final ClassesRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<SessionsPage> fetchSessions({
    required SessionsView view,
    required DateTime now,
    String? groupId,
    int offset = 0,
    int limit = 30,
  }) => _guard(() async {
    final rows = await _dataSource.fetchSessions(
      teacherId: requireUserId(_auth),
      view: view,
      now: now,
      groupId: groupId,
      offset: offset,
      limit: limit,
    );
    return (
      sessions: rows.map(ClassesDto.sessionFromRow).toList(growable: false),
      hasMore: rows.length == limit,
    );
  });

  @override
  Future<ClassSession?> fetchNextSession({
    required DateTime now,
    String? groupId,
  }) async {
    final page = await fetchSessions(
      view: SessionsView.upcoming,
      now: now,
      groupId: groupId,
      limit: 1,
    );
    return page.sessions.firstOrNull;
  }

  @override
  Future<ClassSession> fetchSession(String sessionId) => _guard(() async {
    final row = await _dataSource.fetchSession(requireUserId(_auth), sessionId);
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    return ClassesDto.sessionFromRow(row);
  });

  @override
  Future<ClassSession> createOneTimeSession(OneTimeSessionDraft draft) =>
      _guard(() async {
        requireUserId(_auth);
        final params = ClassesDto.createSessionParams(draft);
        final row = draft.paymentAmount == null
            ? await _dataSource.createManualSession(params)
            : await _dataSource.createManualSessionWithPayment(params);
        return fetchSession(row['id'] as String);
      });

  @override
  Future<ClassSession> rescheduleSession(
    String sessionId, {
    required DateTime startsAt,
    required DateTime endsAt,
  }) => _update(sessionId, {
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': endsAt.toUtc().toIso8601String(),
  });

  @override
  Future<ClassSession> changeSessionLocation(
    String sessionId,
    SessionLocation location,
  ) => _update(sessionId, location.toColumns());

  @override
  Future<ClassSession> setSessionStatus(
    String sessionId,
    SessionStatus status,
  ) => _update(sessionId, {'status': status.backendValue});

  @override
  Future<ClassSession> updateSessionNotes(String sessionId, String? notes) =>
      _update(sessionId, {'notes': trimToNull(notes)});

  @override
  Future<List<ScheduleEntry>> fetchScheduleEntries(String groupId) =>
      _guard(() async {
        final rows = await _dataSource.fetchActiveEntries(
          requireUserId(_auth),
          groupId,
        );
        return rows.map(ClassesDto.entryFromRow).toList(growable: false);
      });

  @override
  Future<ScheduleEntry> fetchScheduleEntry(String entryId) => _guard(() async {
    final row = await _dataSource.fetchEntry(requireUserId(_auth), entryId);
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    return ClassesDto.entryFromRow(row);
  });

  @override
  Future<void> createScheduleEntries(String groupId, List<WeeklySlot> slots) =>
      _guard(() async {
        requireUserId(_auth);
        await _dataSource.insertEntries([
          for (final slot in slots)
            {'group_id': groupId, ...ClassesDto.slotPayload(slot)},
        ]);
      });

  @override
  Future<ScheduleEntry> updateScheduleEntry(String entryId, WeeklySlot slot) =>
      _guard(() async {
        requireUserId(_auth);
        final row = await _dataSource.updateEntry(
          entryId,
          ClassesDto.slotPayload(slot),
        );
        if (row == null) throw const AppFailure(AppFailureType.notFound);
        return ClassesDto.entryFromRow(row);
      });

  @override
  Future<void> deactivateScheduleEntry(String entryId) => _guard(() async {
    requireUserId(_auth);
    final row = await _dataSource.updateEntry(entryId, {'is_active': false});
    if (row == null) throw const AppFailure(AppFailureType.notFound);
  });

  Future<ClassSession> _update(
    String sessionId,
    Map<String, dynamic> payload,
  ) => _guard(() async {
    requireUserId(_auth);
    final row = await _dataSource.updateSession(sessionId, payload);
    if (row == null) throw const AppFailure(AppFailureType.notFound);
    return ClassesDto.sessionFromRow(row);
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ScheduleConflict {
      rethrow;
    } on PostgrestException catch (error) {
      // The only unique index teachers can hit here is the active weekly
      // slot of a group.
      if (error.code == '23505') throw const ScheduleConflict();
      throw mapDataError(error);
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
