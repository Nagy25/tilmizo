import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/student_announcement.dart';
import '../domain/student_announcements_repository.dart';

abstract interface class StudentAnnouncementsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchAnnouncements(
    String groupId, {
    required int offset,
    required int limit,
  });

  Future<Object?> markRead(String announcementId);
}

/// SELECT queries plus `mark_announcement_read`; students never write
/// announcements.
final class SupabaseStudentAnnouncementsDataSource
    implements StudentAnnouncementsRemoteDataSource {
  SupabaseStudentAnnouncementsDataSource(this._client);

  /// Announcement columns with the caller's read marks embedded. RLS shows a
  /// student only their own `announcement_reads` rows.
  static const columns =
      '${Announcement.columns}, reads:announcement_reads(student_id, read_at)';

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchAnnouncements(
    String groupId, {
    required int offset,
    required int limit,
  }) => _client
      .from('announcements')
      .select(columns)
      .eq('group_id', groupId)
      .order('created_at', ascending: false)
      .order('id')
      .range(offset, offset + limit - 1);

  @override
  Future<Object?> markRead(String announcementId) async => await _client.rpc(
    'mark_announcement_read',
    params: {'p_announcement_id': announcementId},
  );
}

final studentAnnouncementsRemoteDataSourceProvider =
    Provider<StudentAnnouncementsRemoteDataSource>(
      (ref) => SupabaseStudentAnnouncementsDataSource(
        ref.watch(supabaseClientProvider),
      ),
    );

final studentAnnouncementsRepositoryProvider =
    Provider<StudentAnnouncementsRepository>(
      (ref) => StudentAnnouncementsRepositoryImpl(
        ref.watch(studentAnnouncementsRemoteDataSourceProvider),
        ref.watch(phoneAuthServiceProvider),
      ),
    );

final class StudentAnnouncementsRepositoryImpl
    implements StudentAnnouncementsRepository {
  StudentAnnouncementsRepositoryImpl(this._dataSource, this._auth);

  final StudentAnnouncementsRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<StudentAnnouncementsPage> fetchAnnouncements(
    String groupId, {
    int offset = 0,
    int limit = 20,
  }) => _guard(() async {
    final studentId = requireUserId(_auth);
    final rows = await _dataSource.fetchAnnouncements(
      groupId,
      offset: offset,
      limit: limit,
    );
    return StudentAnnouncementsPage(
      items: [
        for (final row in rows)
          StudentAnnouncement(
            announcement: Announcement.fromRow(row),
            readAt: _readAt(row['reads'], studentId),
          ),
      ],
      hasMore: rows.length == limit,
    );
  });

  @override
  Future<DateTime> markRead(String announcementId) => _guard(() async {
    requireUserId(_auth);
    final readAt = await _dataSource.markRead(announcementId);
    return DateTime.parse(readAt! as String).toUtc();
  });

  /// The caller's read time; another student's row never counts, as defence
  /// in depth on top of RLS.
  static DateTime? _readAt(Object? reads, String studentId) {
    if (reads is! List) return null;
    for (final read in reads.cast<Map<String, dynamic>>()) {
      if (read['student_id'] == studentId && read['read_at'] is String) {
        return DateTime.parse(read['read_at'] as String).toUtc();
      }
    }
    return null;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      // `mark_announcement_read` rejects with 42501 once this session is no
      // longer approved, which the feed treats like a hidden group.
      if (error is PostgrestException && error.code == '42501') {
        throw const AppFailure(AppFailureType.notFound);
      }
      if (error is TypeError) throw const AppFailure(AppFailureType.unknown);
      throw mapDataError(error);
    }
  }
}
