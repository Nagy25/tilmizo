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
