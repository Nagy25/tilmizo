import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_providers.dart';
import '../auth/phone_auth_service.dart';
import '../errors/app_failure.dart';
import '../errors/require_user_id.dart';
import 'app_notification.dart';
import 'notifications_remote_data_source.dart';
import 'notifications_repository.dart';

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(
      (ref) => SupabaseNotificationsRemoteDataSource(
        ref.watch(supabaseClientProvider),
      ),
    );

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._dataSource, this._auth);

  final NotificationsRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<NotificationsPage> fetchNotifications({
    int offset = 0,
    int limit = 20,
  }) => _guard(() async {
    final rows = await _dataSource.fetchNotifications(
      requireUserId(_auth),
      offset: offset,
      limit: limit,
    );
    return NotificationsPage(
      notifications: rows.map(AppNotification.fromRow).toList(growable: false),
      hasMore: rows.length == limit,
    );
  });

  @override
  Future<int> fetchUnreadCount() =>
      _guard(() => _dataSource.countUnread(requireUserId(_auth)));

  @override
  Future<DateTime> markRead(String notificationId) => _guard(() async {
    requireUserId(_auth);
    final value = await _dataSource.rpc('mark_notification_read', {
      'p_notification_id': notificationId,
    });
    return DateTime.parse(value! as String).toUtc();
  });

  @override
  Future<int> markAllRead() => _guard(() async {
    requireUserId(_auth);
    final value = await _dataSource.rpc('mark_all_notifications_read');
    return (value! as num).toInt();
  });

  @override
  Future<void> registerDevice({
    required String token,
    required NotificationPlatform platform,
    required NotificationApp app,
  }) => _guard(() async {
    requireUserId(_auth);
    await _dataSource.rpc('register_notification_device', {
      'p_token': token,
      'p_platform': platform.value,
      'p_app': app.value,
    });
  });

  @override
  Future<void> revokeDevice(String token) => _guard(() async {
    requireUserId(_auth);
    await _dataSource.rpc('revoke_notification_device', {'p_token': token});
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapNotificationError(error);
    }
  }
}

/// Maps notification RPC rejections to user-safe failures. `42501` means
/// either the token still belongs to another account ([AppFailureType.rejected])
/// or the account cannot receive pushes yet ([AppFailureType.notEligible]).
AppFailure mapNotificationError(Object error) {
  if (error is TypeError) return const AppFailure(AppFailureType.unknown);
  if (error is PostgrestException && error.code == '42501') {
    return error.message.contains('another account')
        ? const AppFailure(AppFailureType.rejected)
        : const AppFailure(AppFailureType.notEligible);
  }
  return mapDataError(error);
}
