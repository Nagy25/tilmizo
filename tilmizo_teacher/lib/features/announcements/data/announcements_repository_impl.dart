import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/announcements_repository.dart';
import 'announcements_remote_data_source.dart';

final announcementsRemoteDataSourceProvider =
    Provider<AnnouncementsRemoteDataSource>(
      (ref) =>
          SupabaseAnnouncementsDataSource(ref.watch(supabaseClientProvider)),
    );

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>(
  (ref) => AnnouncementsRepositoryImpl(
    ref.watch(announcementsRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  AnnouncementsRepositoryImpl(this._dataSource, this._auth);

  final AnnouncementsRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<AnnouncementsPage> fetchAnnouncements(
    String groupId, {
    int offset = 0,
    int limit = 20,
  }) => _guard(() async {
    requireUserId(_auth);
    final rows = await _dataSource.fetchAnnouncements(
      groupId,
      offset: offset,
      limit: limit,
    );
    return AnnouncementsPage(
      announcements: rows.map(Announcement.fromRow).toList(growable: false),
      hasMore: rows.length == limit,
    );
  });

  @override
  Future<Announcement> createAnnouncement(
    String groupId,
    AnnouncementDraft draft,
  ) => _write(
    'create_announcement',
    () => {'p_group_id': groupId, ..._params(draft)},
  );

  @override
  Future<void> deleteAnnouncement(String announcementId) => _guard(() async {
    requireUserId(_auth);
    await _dataSource.rpc('delete_announcement', {
      'p_announcement_id': announcementId,
    });
  });

  Map<String, dynamic> _params(AnnouncementDraft draft) {
    final trimmed = draft.trimmed;
    if (!isValidAnnouncementText(trimmed.title, Announcement.titleMaxLength) ||
        !isValidAnnouncementText(trimmed.body, Announcement.bodyMaxLength)) {
      throw const AppFailure(AppFailureType.invalidInput);
    }
    return {'p_title': trimmed.title, 'p_body': trimmed.body};
  }

  /// Validates through [params] inside the guard, so invalid drafts fail
  /// as an [AppFailure] without reaching the backend.
  Future<Announcement> _write(
    String function,
    Map<String, dynamic> Function() params,
  ) => _guard(() async {
    requireUserId(_auth);
    final row = await _dataSource.rpc(function, params());
    return Announcement.fromRow(Map<String, dynamic>.from(row! as Map));
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapAnnouncementError(error);
    }
  }
}

/// Maps RPC rejections to user-safe failures: `42501` from the writable-group
/// check becomes [AppFailureType.notEligible] (archived, suspended or not
/// owned), check-constraint violations become invalid input.
AppFailure mapAnnouncementError(Object error) {
  if (error is TypeError) return const AppFailure(AppFailureType.unknown);
  if (error is PostgrestException) {
    switch (error.code) {
      case '42501':
        return const AppFailure(AppFailureType.notEligible);
      case '23514' || '22001' || '23502':
        return const AppFailure(AppFailureType.invalidInput);
    }
  }
  return mapDataError(error);
}
