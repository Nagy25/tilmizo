import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_notification.dart';

/// SELECT access to `user_notifications` and the notification RPCs.
abstract interface class NotificationsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchNotifications(
    String userId, {
    required int offset,
    required int limit,
  });

  Future<int> countUnread(String userId);

  /// Calls one RPC with named parameters and returns its result.
  Future<Object?> rpc(String function, [Map<String, dynamic>? params]);
}

final class SupabaseNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  SupabaseNotificationsRemoteDataSource(this._client);

  final SupabaseClient _client;

  // RLS already limits rows to the recipient; the user filter matches the
  // `(user_id, created_at desc)` indexes.
  @override
  Future<List<Map<String, dynamic>>> fetchNotifications(
    String userId, {
    required int offset,
    required int limit,
  }) => _client
      .from('user_notifications')
      .select(AppNotification.columns)
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .order('id')
      .range(offset, offset + limit - 1);

  @override
  Future<int> countUnread(String userId) => _client
      .from('user_notifications')
      .count(CountOption.exact)
      .eq('user_id', userId)
      .isFilter('read_at', null);

  @override
  Future<Object?> rpc(String function, [Map<String, dynamic>? params]) async =>
      await _client.rpc(function, params: params);
}
