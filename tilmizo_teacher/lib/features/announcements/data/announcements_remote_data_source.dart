import 'package:core_package/core_package.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SELECT access to `announcements` and the teacher announcement RPCs. The
/// client never writes the table directly.
abstract interface class AnnouncementsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchAnnouncements(
    String groupId, {
    required int offset,
    required int limit,
  });

  /// Calls one RPC with named parameters and returns its result.
  Future<Object?> rpc(String function, Map<String, dynamic> params);
}

final class SupabaseAnnouncementsDataSource
    implements AnnouncementsRemoteDataSource {
  SupabaseAnnouncementsDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchAnnouncements(
    String groupId, {
    required int offset,
    required int limit,
  }) => _client
      .from('announcements')
      .select(Announcement.columns)
      .eq('group_id', groupId)
      .order('created_at', ascending: false)
      .order('id')
      .range(offset, offset + limit - 1);

  @override
  Future<Object?> rpc(String function, Map<String, dynamic> params) async =>
      await _client.rpc(function, params: params);
}
