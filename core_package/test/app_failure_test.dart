import 'dart:async';

import 'package:core_package/core_package.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  AppFailureType map(Object error) => mapDataError(error).type;
  PostgrestException pg(String code, [String message = 'raw']) =>
      PostgrestException(message: message, code: code);

  test('maps PostgREST and RPC error codes to stable failures', () {
    expect(map(pg('PGRST116')), AppFailureType.notFound);
    expect(map(pg('P0002')), AppFailureType.notFound);
    expect(map(pg('22023')), AppFailureType.invalidInput);
    expect(map(pg('55000')), AppFailureType.notEligible);
    expect(map(pg('42501')), AppFailureType.rejected);
    expect(map(pg('PGRST301')), AppFailureType.sessionExpired);
    expect(
      map(pg('23505', 'duplicate key "groups_invite_code_key"')),
      AppFailureType.duplicateInviteCode,
    );
    expect(map(pg('XX000')), AppFailureType.unknown);
  });

  test('maps network, auth, and unknown errors', () {
    expect(map(TimeoutException('slow')), AppFailureType.network);
    expect(map(const AuthApiException('raw')), AppFailureType.sessionExpired);
    expect(map(StateError('x')), AppFailureType.unknown);
    const failure = AppFailure(AppFailureType.notEligible);
    expect(mapDataError(failure), same(failure));
  });

  test('trimToNull trims and nulls blank values', () {
    expect(trimToNull('  a '), 'a');
    expect(trimToNull('  '), isNull);
  });
}
