import 'package:core_package/core_package.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'payments_dto.dart';

/// Raw access to payment tables (SELECT only) and the teacher payment RPCs.
/// The client never inserts, updates or deletes financial rows directly.
abstract interface class PaymentsRemoteDataSource {
  Future<Map<String, dynamic>?> fetchActivePlan(String groupId);

  /// Current (unpaid or paid) obligations of [groupId], newest first.
  Future<List<Map<String, dynamic>>> fetchObligations(String groupId);

  Future<Map<String, dynamic>?> fetchActiveSessionItem(String sessionId);

  /// Calls one teacher RPC with named parameters and returns its result.
  Future<Object?> rpc(String function, Map<String, dynamic> params);
}

final class SupabasePaymentsDataSource implements PaymentsRemoteDataSource {
  SupabasePaymentsDataSource(this._client);

  /// PostgREST's default maximum page; one group never approaches it.
  static const _maxRows = 1000;

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchActivePlan(String groupId) => _client
      .from('monthly_payment_plans')
      .select(PaymentsDto.planColumns)
      .eq('group_id', groupId)
      .isFilter('stopped_at', null)
      .maybeSingle();

  @override
  Future<List<Map<String, dynamic>>> fetchObligations(String groupId) => _client
      .from('payment_obligations')
      .select(PaymentsDto.obligationColumns)
      .eq('group_id', groupId)
      .inFilter('status', [
        for (final status in PaymentStatus.current) status.backendValue,
      ])
      .order('due_on', ascending: false)
      .order('created_at', ascending: false)
      .order('id')
      .limit(_maxRows);

  @override
  Future<Map<String, dynamic>?> fetchActiveSessionItem(String sessionId) =>
      _client
          .from('session_payment_items')
          .select('id, amount')
          .eq('session_id', sessionId)
          .isFilter('cancelled_at', null)
          .maybeSingle();

  @override
  Future<Object?> rpc(String function, Map<String, dynamic> params) async =>
      await _client.rpc(function, params: params);
}
