import 'package:core_package/core_package.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/student_payments_repository.dart';

abstract interface class StudentPaymentsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchObligations({
    required String studentId,
    String? groupId,
  });
}

/// SELECT-only queries; the student app never writes financial rows.
final class SupabaseStudentPaymentsDataSource
    implements StudentPaymentsRemoteDataSource {
  SupabaseStudentPaymentsDataSource(this._client);

  /// PostgREST's default maximum page.
  static const _maxRows = 1000;

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchObligations({
    required String studentId,
    String? groupId,
  }) {
    var query = _client
        .from('payment_obligations')
        .select(PaymentObligation.columns)
        .eq('student_id', studentId)
        .inFilter('status', [
          for (final status in PaymentStatus.current) status.backendValue,
        ]);
    if (groupId != null) query = query.eq('group_id', groupId);
    return query
        .order('due_on', ascending: false)
        .order('created_at', ascending: false)
        .order('id')
        .limit(_maxRows);
  }
}

final studentPaymentsRemoteDataSourceProvider =
    Provider<StudentPaymentsRemoteDataSource>(
      (ref) =>
          SupabaseStudentPaymentsDataSource(ref.watch(supabaseClientProvider)),
    );

final studentPaymentsRepositoryProvider = Provider<StudentPaymentsRepository>(
  (ref) => StudentPaymentsRepositoryImpl(
    ref.watch(studentPaymentsRemoteDataSourceProvider),
    ref.watch(phoneAuthServiceProvider),
  ),
);

final class StudentPaymentsRepositoryImpl implements StudentPaymentsRepository {
  StudentPaymentsRepositoryImpl(this._dataSource, this._auth);

  final StudentPaymentsRemoteDataSource _dataSource;
  final PhoneAuthService _auth;

  @override
  Future<List<PaymentObligation>> fetchMyPayments({String? groupId}) async {
    try {
      final studentId = requireUserId(_auth);
      final rows = await _dataSource.fetchObligations(
        studentId: studentId,
        groupId: groupId,
      );
      return [
        for (final obligation in rows.map(PaymentObligation.fromRow))
          // Defence in depth: never show another student's or a void row.
          if (obligation.studentId == studentId &&
              obligation.status != PaymentStatus.voided)
            obligation,
      ];
    } on FormatException {
      throw const AppFailure(AppFailureType.unknown);
    } catch (error) {
      throw mapDataError(error);
    }
  }
}
