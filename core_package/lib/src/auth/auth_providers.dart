import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_session_status.dart';
import 'phone_auth_service.dart';
import 'supabase_phone_auth_service.dart';

/// The initialized Supabase client. Call `initializeSupabase` before reading
/// it, or override it in tests.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final phoneAuthServiceProvider = Provider<PhoneAuthService>(
  (ref) => SupabasePhoneAuthService(ref.watch(supabaseClientProvider).auth),
);

final authSessionStatusProvider = StreamProvider<AuthSessionStatus>(
  (ref) => ref.watch(phoneAuthServiceProvider).sessionStatus,
);
