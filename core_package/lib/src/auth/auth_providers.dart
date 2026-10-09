import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../notifications/push_registration_controller.dart';
import '../resources/resource_file_service.dart';
import 'auth_session_status.dart';
import 'phone_auth_service.dart';
import 'supabase_phone_auth_service.dart';

/// The initialized Supabase client. Call `initializeSupabase` before reading
/// it, or override it in tests.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Signing out first revokes this device's push token, then clears cached
/// resource files and images, so the next account on the device cannot open
/// them.
final phoneAuthServiceProvider = Provider<PhoneAuthService>(
  (ref) => SupabasePhoneAuthService(
    ref.watch(supabaseClientProvider).auth,
    onBeforeSignOut: () =>
        ref.read(pushRegistrationProvider.notifier).prepareSignOut(),
    onSignedOut: () => ref.read(resourceFileServiceProvider).clearCache(),
  ),
);

final authSessionStatusProvider = StreamProvider<AuthSessionStatus>(
  (ref) => ref.watch(phoneAuthServiceProvider).sessionStatus,
);
