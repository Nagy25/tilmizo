# tilmizo_teacher

The Telmizo teacher application (Arabic RTL) for Android, iOS, and web.

## Configuration

The app reads its Supabase connection at compile time and refuses to start
without it. Copy the example and fill in the project's publishable key:

```bash
cp config/env.example.json config/env.local.json
```

`config/env.local.json` is gitignored. Never put a service-role or secret key
in it. The current local file also enables Supabase's temporary test-phone
flow; it is not a production authentication configuration.

## Running

```bash
flutter run --dart-define-from-file=config/env.local.json
```

## Code generation

After changing translations in `assets/translations/`:

```bash
dart run easy_localization:generate -S assets/translations -O lib/generated
dart run easy_localization:generate -S assets/translations -O lib/generated -f keys -o locale_keys.g.dart
```

After changing routes or routable screens:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Phase 1 flow

Splash → phone login → six-digit OTP → profile completion (only when
incomplete) → empty groups or groups dashboard → create, view, edit,
activate/deactivate, and delete owned groups.

For development, `config/env.local.json` pre-fills the synthetic Supabase test
number `+201000000000` and fixed code `123456`. Supabase verifies that code and
creates a real session, but bypasses the Send SMS hook, so no SMS or WhatsApp
message is sent. Before production, remove the test mapping in Supabase, turn
off `ENABLE_TEST_PHONE_AUTH`, remove both test values, and configure an
approved OTP delivery provider. The retained WhatsApp Edge Function is a
future delivery option and is not used by the test number.

## Push notifications

Firebase Cloud Messaging uses the native `android/app/google-services.json`
(applied by the `com.google.gms.google-services` Gradle plugin). Never add the
Firebase service-account JSON to the app; it belongs only in the Supabase
`FCM_SERVICE_ACCOUNT_JSON` Edge Function secret.

After sign-in the mobile app asks for notification permission once per
installation; web asks when the teacher presses **Enable notifications** in
the profile. Once permission is granted, it registers the FCM token with
`register_notification_device`,
and revokes it before sign-out. A push payload (`event_type`, `target_id`)
is only a navigation hint: the target is re-read under RLS, and the
notification center opens when it is unavailable. The in-app notification
center works without the permission.

Teacher web push requires a Web Push key pair in Firebase Console → Project
settings → Cloud Messaging → Web Push certificates. Put its **public** key in
`WEB_PUSH_VAPID_KEY` in the web build's Dart defines (for local builds,
`config/env.local.json`). Keep the private key in Firebase. The web app and
`web/firebase-messaging-sw.js` must use the same Firebase project. Serve the
app over HTTPS or localhost, and allow notifications in the browser. The FCM
plugin registers the messaging worker when obtaining a token; no additional
registration in `web/index.html` is needed. `web/flutter_bootstrap.js` leaves
Flutter's legacy PWA worker disabled so it cannot replace the messaging worker.
Apply the
`20261009164005_teacher_web_push` Supabase migration before using web push so
`register_notification_device` accepts `platform=web` for teacher sessions.
On web, the teacher must press **Enable notifications** on the home screen,
notification center, or profile; the browser permission prompt cannot be
opened automatically after sign-in.
The home notice can be closed for the current session; it appears again after
the next sign-in or app restart while notifications remain disabled.
Build with `flutter build web --dart-define-from-file=config/env.local.json`
after adding the public key, then deploy the rebuilt web assets.

The backend does not create teacher-directed events yet, so the teacher
notification center stays empty until it does. Existing student-directed
events do not become teacher notifications merely by registering a token.

iOS push is disabled until it is configured:

1. Add `ios/Runner/GoogleService-Info.plist` for this app's bundle ID.
2. Enable the Push Notifications capability and the Remote notifications
   background mode, and upload an APNs key in the Firebase console.
3. Set `"IOS_PUSH_ENABLED": true` in `config/env.local.json`.
