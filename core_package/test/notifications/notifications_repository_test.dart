import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_auth.dart';

final class _FakeDataSource implements NotificationsRemoteDataSource {
  List<Map<String, dynamic>> rows = [];
  Object? rpcResult;
  Object? error;
  final rpcCalls = <(String, Map<String, dynamic>?)>[];
  final fetches = <(String, int, int)>[];

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications(
    String userId, {
    required int offset,
    required int limit,
  }) async {
    fetches.add((userId, offset, limit));
    if (error case final error?) throw error;
    return rows;
  }

  @override
  Future<int> countUnread(String userId) async {
    if (error case final error?) throw error;
    return 3;
  }

  @override
  Future<Object?> rpc(String function, [Map<String, dynamic>? params]) async {
    rpcCalls.add((function, params));
    if (error case final error?) throw error;
    return rpcResult;
  }
}

Map<String, dynamic> _row(String id) => {
  'id': id,
  'event_type': 'homework_new',
  'title': 'واجب جديد',
  'created_at': '2026-10-01T09:00:00Z',
};

void main() {
  late _FakeDataSource source;
  late FakeAuth auth;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    source = _FakeDataSource();
    auth = FakeAuth(userId: 'user-1');
    repository = NotificationsRepositoryImpl(source, auth);
  });

  test('pages are scoped to the signed-in user', () async {
    source.rows = [_row('a'), _row('b')];
    final page = await repository.fetchNotifications(offset: 20, limit: 2);

    expect(source.fetches.single, ('user-1', 20, 2));
    expect(page.notifications.map((n) => n.id), ['a', 'b']);
    expect(page.hasMore, isTrue);
    expect(await repository.fetchUnreadCount(), 3);
  });

  test('requires a session', () async {
    auth.userId = null;
    await expectLater(
      repository.fetchNotifications(),
      throwsA(const AppFailure(AppFailureType.sessionExpired)),
    );
    expect(source.fetches, isEmpty);
  });

  test('mark read RPCs return the stored values', () async {
    source.rpcResult = '2026-10-02T08:00:00+00:00';
    expect(await repository.markRead('n1'), DateTime.utc(2026, 10, 2, 8));
    expect(source.rpcCalls.last.$1, 'mark_notification_read');
    expect(source.rpcCalls.last.$2, {'p_notification_id': 'n1'});

    source.rpcResult = 4;
    expect(await repository.markAllRead(), 4);
    expect(source.rpcCalls.last.$1, 'mark_all_notifications_read');
  });

  test('registration sends the app and platform values', () async {
    await repository.registerDevice(
      token: 't',
      platform: NotificationPlatform.ios,
      app: NotificationApp.teacher,
    );
    await repository.revokeDevice('t');

    expect(source.rpcCalls.map((call) => call.$1), [
      'register_notification_device',
      'revoke_notification_device',
    ]);
    expect(source.rpcCalls.first.$2, {
      'p_token': 't',
      'p_platform': 'ios',
      'p_app': 'teacher',
    });
    expect(source.rpcCalls.last.$2, {'p_token': 't'});
  });

  test('maps registration rejections', () async {
    Future<void> register() => repository.registerDevice(
      token: 't',
      platform: NotificationPlatform.android,
      app: NotificationApp.student,
    );

    source.error = const PostgrestException(
      message: 'Wrong app for account',
      code: '42501',
    );
    await expectLater(
      register(),
      throwsA(const AppFailure(AppFailureType.notEligible)),
    );

    source.error = const PostgrestException(
      message: 'Device token belongs to another account',
      code: '42501',
    );
    await expectLater(
      register(),
      throwsA(const AppFailure(AppFailureType.rejected)),
    );

    source.error = const PostgrestException(
      message: 'Notification not found',
      code: 'P0002',
    );
    await expectLater(
      repository.markRead('x'),
      throwsA(const AppFailure(AppFailureType.notFound)),
    );
  });
}
