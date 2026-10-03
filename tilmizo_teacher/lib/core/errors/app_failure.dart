import 'package:core_package/core_package.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stable data-access failure categories safe to present to users.
enum AppFailureType {
  network,
  notFound,
  duplicateInviteCode,
  sessionExpired,
  rejected,
  unknown,
}

/// A repository failure that never carries raw PostgREST or SQL messages.
final class AppFailure implements Exception {
  const AppFailure(this.type);

  final AppFailureType type;

  @override
  String toString() => 'AppFailure(${type.name})';
}

/// Maps errors from the Supabase Data API to an [AppFailure].
///
/// Missing rows and rows hidden by RLS are both reported as
/// [AppFailureType.notFound], so another teacher's records are
/// indistinguishable from nonexistent ones.
AppFailure mapDataError(Object error) {
  if (error is AppFailure) return error;
  if (isNetworkError(error)) return const AppFailure(AppFailureType.network);
  if (error is AuthException) {
    return const AppFailure(AppFailureType.sessionExpired);
  }
  if (error is! PostgrestException) {
    return const AppFailure(AppFailureType.unknown);
  }

  final details = '${error.message} ${error.details ?? ''}';
  return switch (error.code) {
    '23505' when details.contains('invite_code') => const AppFailure(
      AppFailureType.duplicateInviteCode,
    ),
    'PGRST116' => const AppFailure(AppFailureType.notFound),
    'PGRST301' ||
    'PGRST302' ||
    'PGRST303' => const AppFailure(AppFailureType.sessionExpired),
    '401' => const AppFailure(AppFailureType.sessionExpired),
    '42501' ||
    '23503' ||
    '23514' ||
    '23502' ||
    '22001' => const AppFailure(AppFailureType.rejected),
    _ => const AppFailure(AppFailureType.unknown),
  };
}
