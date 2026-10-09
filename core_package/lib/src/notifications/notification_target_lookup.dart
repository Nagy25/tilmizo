import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_providers.dart';
import '../errors/app_failure.dart';
import 'app_notification.dart';

/// Re-reads a notification's target under the normal RLS rules before the
/// app navigates to it. A push payload is only a hint: it grants no access.
abstract interface class NotificationTargetLookup {
  /// The target's group when the signed-in user can still read it, `null`
  /// when it is missing, hidden, or the notification has no target.
  /// Throws [AppFailure] when the check itself failed, such as offline.
  Future<String?> visibleGroupId(NotificationTarget target);
}

final notificationTargetLookupProvider = Provider<NotificationTargetLookup>(
  (ref) => SupabaseNotificationTargetLookup(ref.watch(supabaseClientProvider)),
);

final class SupabaseNotificationTargetLookup
    implements NotificationTargetLookup {
  SupabaseNotificationTargetLookup(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> visibleGroupId(NotificationTarget target) async {
    final id = target.targetId;
    final table = switch (target.eventType.targetKind) {
      NotificationTargetKind.homework => 'homework',
      NotificationTargetKind.announcement => 'announcements',
      NotificationTargetKind.resource => 'resources',
      NotificationTargetKind.session => 'class_sessions',
      NotificationTargetKind.payment => 'payment_obligations',
      NotificationTargetKind.none => null,
    };
    if (id == null || table == null) return null;
    try {
      final row = await _client
          .from(table)
          .select('group_id')
          .eq('id', id)
          .maybeSingle();
      final groupId = row?['group_id'];
      return groupId is String ? groupId : null;
    } catch (error) {
      final failure = mapDataError(error);
      if (failure.type == AppFailureType.notFound ||
          failure.type == AppFailureType.rejected) {
        return null;
      }
      throw failure;
    }
  }
}
