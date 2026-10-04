import 'package:supabase_flutter/supabase_flutter.dart';

import 'network_errors.dart';

/// Stable data-access failure categories safe to present to users.
enum AppFailureType {
  network,
  notFound,
  duplicateInviteCode,
  sessionExpired,
  rejected,

  /// The backend rejected malformed input, such as a blank invite code.
  invalidInput,

  /// The record exists but is not in a state that allows the action.
  notEligible,
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
/// [AppFailureType.notFound], so another user's records are
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
    'PGRST116' || 'P0002' => const AppFailure(AppFailureType.notFound),
    '22023' => const AppFailure(AppFailureType.invalidInput),
    '55000' => const AppFailure(AppFailureType.notEligible),
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
