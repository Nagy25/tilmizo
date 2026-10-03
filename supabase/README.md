# Supabase Phase 1 Teacher Backend

This directory contains the backend-only Phase 1 setup for Supabase project
`tilmizo` (`trmkevgtjdbvbzyknaih`). Authentication is designed around a
verified Egyptian mobile number. Development currently uses Supabase's hosted
test-phone mapping; the future WhatsApp delivery integration is retained but
is not used by the synthetic test number.

## Database migrations

Run `phase_1_teacher_backend.sql` in the Supabase SQL Editor. The script creates
the `profiles` and `groups` tables, their constraints and indexes, automatic
profile and timestamp triggers, explicit Data API grants, and all RLS policies.

For an environment that already ran the original Phase 1 script, run
`phase_1_whatsapp_auth.sql` once. It adds the teaching specialization, makes the
verified Egyptian mobile number the immutable profile identity, and updates the
Auth triggers and grants. The migration stops without committing if an
existing Auth user lacks a valid Egyptian mobile number.

Run `phase_1_phone_normalization.sql` after either existing setup. It keeps the
strict E.164 profile constraint while canonicalizing the phone value exposed by
Supabase's hosted test-number flow, which may omit the leading `+` inside Auth
triggers. The same normalization is included in the current base migrations.

## Authentication configuration

### Current intended settings

- New user signups: enabled.
- Anonymous sign-ins: disabled.
- Email provider: disabled.
- Google provider: disabled.
- Apple provider: disabled.
- Phone provider: enabled for the restricted hosted test-phone flow.
- Phone confirmations: enabled.
- OTP length: six digits; OTP expiry/cooldown: 60 seconds.
- Test mapping: `+201000000000` → `123456`, valid until 2026-10-31.
- Site URL: keep `http://localhost:3000` until application redirect handling is
  designed.
- Redirect allowlist: keep empty until application deep links are designed.

The mapped test number bypasses delivery and therefore does not invoke the
WhatsApp hook. It still uses Supabase's normal `signInWithOtp` and `verifyOtp`
APIs, creates or reuses `auth.users`, issues a real session, runs the profile
trigger, and applies normal RLS. It must never be treated as production
authentication because anyone who knows the published test credentials can
access the same test account.

Before production, delete the test mapping, disable the application's test
mode and remove its test values, then configure and acceptance-test an
approved delivery provider. Keep Phone confirmation enabled.

### WhatsApp OTP through Meta Cloud API

Telmizo uses Supabase Phone Auth with an HTTP Send SMS Hook. Supabase creates
the OTP, verifies it, creates or reuses `auth.users`, issues sessions, and
enforces Auth rate limits. The `send-whatsapp-otp` Edge Function only delivers
that OTP through an approved Meta authentication template.

Development setup:

1. Create a dedicated Meta app and Business Portfolio named `Telmizo`; do not
   reuse an unrelated Meta app.
2. Add the WhatsApp business-messaging use case and keep the app in Development
   mode. Meta's generated test sender can validate basic Cloud API access, but
   its generated test WhatsApp Business Account may not be permitted to create
   custom authentication templates.
3. Configure a real WhatsApp Business Account and sender before enabling Auth,
   register an Egyptian `+20` test recipient, and create the Arabic
   `telmizo_login_code` authentication template with a copy-code button. The
   default `hello_world` and Jasper test templates cannot carry a
   Supabase-generated OTP and must not be used as an authentication fallback.
4. Deploy `functions/send-whatsapp-otp` with JWT verification disabled. The
   function authenticates Supabase Auth using Standard Webhooks instead.
5. Configure these production secrets in the Supabase dashboard:
   `SEND_SMS_HOOK_SECRET`, `META_WHATSAPP_ACCESS_TOKEN`,
   `META_WHATSAPP_PHONE_NUMBER_ID`, `META_WHATSAPP_GRAPH_API_VERSION`,
   `META_WHATSAPP_TEMPLATE_NAME`, `META_WHATSAPP_TEMPLATE_LANGUAGE`, and
   `META_WHATSAPP_ALLOWED_RECIPIENTS`.
6. Register the function under **Authentication > Auth Hooks > Send SMS** with
   the same signing secret.
7. Only after the hook is deployed, the authentication template is approved,
   and the development recipient allowlist is configured, enable Phone Auth
   and phone confirmations, keep the OTP length at six digits, and use a
   60-second expiry/cooldown.

The development allowlist is mandatory and fail-closed. It accepts a
comma-separated set of Egyptian E.164 numbers and prevents the temporary test
sender from becoming a public authentication route. Never place real phone
numbers or secret values in source control or chat.

The Meta temporary access token is for development only. Production requires
a verified Telmizo Business Portfolio, a registered production WhatsApp
sender, an approved authentication template, and a permanent system-user token
with the required WhatsApp permissions. Remove the development allowlist only
as part of a separate reviewed production rollout.

Official guides:

- https://supabase.com/docs/guides/auth/auth-hooks/send-sms-hook
- https://supabase.com/docs/guides/functions/secrets
- https://developers.facebook.com/documentation/business-messaging/whatsapp/overview

### Number format and profile completion

Only Egyptian mobile numbers in canonical E.164 format are accepted:
`+2010XXXXXXXX`, `+2011XXXXXXXX`, `+2012XXXXXXXX`, or `+2015XXXXXXXX`.
The future client must remove the local leading zero before adding `+20`.

The Auth trigger copies the verified number into `profiles.phone`. A profile is
complete when `full_name`, `phone`, and `teaching_subject` are all non-null and
nonblank. The verified phone is read-only through the Data API; changing it
must use Supabase Auth's verified phone-change flow.

## Sessions and logout

The project currently has no session time-box and no inactivity timeout, so a
session can persist through refresh-token rotation. Access tokens expire after
3600 seconds, compromised refresh-token detection is enabled, and the refresh
token reuse interval is 10 seconds.

Persistent local session storage and logout are client responsibilities. The
future Flutter implementation must restore the Supabase session and call the
Supabase Auth `signOut` API for logout.

## Edge Function security

- The function rejects unsigned requests and does not trust a client JWT.
- Only Egyptian mobile numbers in the development allowlist can receive OTPs.
- Meta tokens and hook secrets are stored only as Supabase Edge Function
  secrets.
- Logs contain the Meta message identifier and a masked phone number; they do
  not contain access tokens, OTPs, or complete phone numbers.
- A Meta error is returned to Supabase Auth as a generic delivery failure so
  provider details are not exposed to clients.

## Security decisions

- The `anon` role has no access to either application table.
- Authenticated users receive only the table operations and mutable columns
  required by Phase 1.
- RLS uses `auth.uid()` for ownership and protects both existing and resulting
  rows during updates.
- Profile IDs, verified phone numbers, group IDs, group ownership, and
  timestamps are not client writable.
- Auth trigger functions use `SECURITY DEFINER` only because the Auth service
  must synchronize profiles. They live in the unexposed `private` schema, have
  an empty search path, validate trigger context, and are not executable by API
  roles.
- Authentication metadata initializes optional display fields only. It is not
  used for authorization.
- Every authenticated Phase 1 user is treated as a teacher because roles and
  students are outside this phase.
- Invite codes are nullable, case-sensitive, and not generated by the database.
