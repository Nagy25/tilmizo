# tilmizo_student

The Telmizo student application (Arabic RTL) for Android and iOS.

## Configuration

The app reads its Supabase connection at compile time and refuses to start
without it:

```bash
cp config/env.example.json config/env.local.json
```

Put the project's publishable key in `config/env.local.json` (gitignored).
Never put a service-role or secret key in either file.

## Running

```bash
flutter run --dart-define-from-file=config/env.local.json
```

## Development test phone

`config/env.local.json` enables Supabase's temporary test-phone flow and
prefills `+201100000000` with code `123456`. Supabase still runs
`signInWithOtp` and `verifyOTP`, creates a real session and `auth.users` row,
runs the profile trigger, and enforces RLS; it only skips SMS/WhatsApp
delivery. The teacher app uses its own mapping, `+201000000000` / `123456`.

Before production:

1. Remove **both** test-phone mappings in Supabase Authentication.
2. Set `ENABLE_TEST_PHONE_AUTH` to `false` and remove `TEST_PHONE_NUMBER` and
   `TEST_PHONE_OTP` from each app's environment file.
3. Configure an approved OTP delivery provider.

## Group access and devices

A student joins a group with the teacher's invite code. The teacher sees the
device's display name and platform and must approve before any group content
is readable. Access is bound to one approved device and Supabase session per
group; a new device asks for approval without the invite code, and the
previous device keeps access until the teacher approves the change.

The app sends a random per-installation UUID (stored in SharedPreferences)
plus the device's display name, platform, and app version. The backend stores
only a SHA-256 hash of the installation ID. No IMEI, Android ID, IDFV, MAC
address, serial number, or advertising identifier is collected.

The installation ID is a usability control, **not hardware attestation**: a
modified client could spoof it. Play Integrity / App Attest are not part of
this phase.

The app expects these backend RPCs in addition to the Phase 2 ones (see
`../supabase/phase_2_student_access_support.sql`):
`get_my_group_access_overview()`, whose `access_state` drives every status
screen, and `request_group_device_replacement(p_membership_id,
p_installation_id, p_device_name, p_platform, p_app_version)`.

The overview reports both "this device was replaced" and "this is a new
device" as `different_device`. The app keeps a local list of groups approved
on this installation (cleared on sign-out) purely to choose between those two
messages; it never grants access.

## Code generation

After changing translations:

```bash
flutter pub run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart
flutter pub run easy_localization:generate -S assets/translations -O lib/generated -f json -o codegen_loader.g.dart
```

After changing routes or routable screens:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Push notifications

Firebase Cloud Messaging uses the native `android/app/google-services.json`
(applied by the `com.google.gms.google-services` Gradle plugin). Never add the
Firebase service-account JSON to the app; it belongs only in the Supabase
`FCM_SERVICE_ACCOUNT_JSON` Edge Function secret.

After sign-in the app asks for notification permission once per
installation, registers the FCM token with `register_notification_device`,
and revokes it before sign-out. A push payload (`event_type`, `target_id`)
is only a navigation hint: the target is re-read under RLS, and the
notification center opens when it is unavailable. The in-app notification
center works without the permission.

Taps on announcement and resource notifications open the group on the
matching tab (`/groups/:groupId?tab=announcements`).

iOS push is disabled until it is configured:

1. Add `ios/Runner/GoogleService-Info.plist` for this app's bundle ID.
2. Enable the Push Notifications capability and the Remote notifications
   background mode, and upload an APNs key in the Firebase console.
3. Set `"IOS_PUSH_ENABLED": true` in `config/env.local.json`.
