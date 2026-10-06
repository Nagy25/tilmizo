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
- Teacher test mapping: `+201000000000` → `123456`, valid until
  2026-10-31.
- Student test mapping: `+201100000000` → `123456`, valid until
  2026-10-31.
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

## Phase 2 group access and device approval

Run `phase_2_group_access.sql` after the Phase 1 migrations. It adds a
group-scoped approval workflow without adding attendance, lessons, chat,
payments, or other classroom features.

- `student_devices` stores a server-side SHA-256 hash of the random app
  installation identifier plus a teacher-readable device name and platform.
  It never stores IMEI, serial number, MAC address, or advertising identifiers.
- `group_join_requests` records initial join and replacement-device requests.
- `group_memberships` allows one approved device and one approved Supabase
  session per student per group.
- `request_group_access` looks up an active invite code without exposing group
  discovery, records the current JWT `session_id`, and returns either a pending
  request or immediate access for the already-approved installation.
- `decide_group_access_request` lets only the owning teacher accept or reject a
  pending request. Acceptance atomically replaces the previous approved device
  and session.
- `revoke_group_member_access` lets the owning teacher suspend group access;
  `leave_group` lets a student remove their own access.

RLS requires the authenticated student's UID and the approved JWT session ID
for group and membership reads. A replaced session therefore loses server-side
group access immediately even though its stateless access token may remain
cryptographically valid until expiry. Flutter should observe request or
membership changes, clear group caches, and sign out or show the pending-access
screen when access is revoked. This controls access to each teacher's group; it
does not allow one teacher to terminate a student's access to other teachers.

The installation identifier is an application control, not hardware
attestation. A determined modified client may spoof it. Play Integrity and App
Attest are intentionally deferred beyond this phase.

The Security Advisor reports the four public workflow RPCs as callable
`SECURITY DEFINER` functions. This is intentional: authenticated clients have
no direct mutation grants on the three Phase 2 tables, so these narrowly
scoped functions are the mutation boundary. Each function has an empty search
path, derives the caller and session from the verified JWT, validates ownership
or membership internally, and is not executable by `anon` or `PUBLIC`.

Run `phase_2_student_access_support.sql` after `phase_2_group_access.sql`. It
adds the safe `get_my_group_access_overview` read model used to restore pending,
rejected, approved, replaced-device, suspended, and removed states without
returning invite codes, installation hashes, or session UUIDs. It also adds
`request_group_device_replacement`, which lets an authenticated student request
a new device for their own active membership without re-entering the invite
code. The existing device remains active until the teacher approves the
replacement. Students may read their own membership status from any session,
but the `groups` policy remains bound to the single approved JWT session.

Direct authenticated reads of the three Phase 2 workflow tables are
column-limited. Clients must name the required columns explicitly; wildcard
selects are intentionally rejected. The Data API never grants authenticated
users direct access to `installation_id_hash`, request `session_id`, or
membership `approved_session_id`. The safe overview RPC exposes only derived
booleans and the state needed by the UI.

The Security Advisor will also report these two narrowly scoped public RPCs as
callable `SECURITY DEFINER` functions. They use the same empty-search-path,
JWT-derived identity, ownership validation, and explicit grant pattern as the
original Phase 2 workflow functions.

## Phase 3 schedules, class sessions, and attendance

Apply the versioned `phase_3_sessions_schedule_attendance` migration after both
Phase 2 scripts, followed by `phase_3_foreign_key_indexes`. The first two
phases were largely applied through SQL scripts rather than migration history;
the Phase 3 migrations depend on their existing tables and do not rewrite the
older migration records.

- `group_schedule_entries` stores Cairo-local weekly time slots and default
  physical locations or HTTPS meeting links. An active slot immediately fills
  the next 28 Cairo calendar days. `pg_cron` repeats this daily at 00:10 UTC.
- `class_sessions` stores actual UTC-aware timestamps and copied location
  details. `(schedule_entry_id, original_date)` prevents the job from
  duplicating or reviving a rescheduled or cancelled occurrence. Manual extra
  sessions have no schedule entry.
- `session_attendance` stores at most one status per session and student. No
  rows are seeded when a session is created; a missing row means `not_marked`.
  Existing rows remain when membership status changes.
- Approved students may read the weekly schedule, class sessions (including
  notes and meeting links), and only their own attendance. Teachers manage
  their owned groups. All three tables have RLS and explicit API grants.
- Authenticated teachers use `create_manual_class_session`,
  `set_session_attendance`, and `archive_group` RPCs. These public
  `SECURITY DEFINER` functions check group ownership internally and are not
  executable by `anon`. The private generation functions have no client
  execution grant.
- Archiving sets `groups.is_active = false`, stops generation, and keeps
  historical student read access. A group with class sessions cannot be hard
  deleted. The teacher app's existing direct-delete action must switch to
  `archive_group` during the later Flutter phase; until then, deleting such a
  group returns a foreign-key error.

The Phase 3 security advisor notices for the three public RPCs are expected:
their authenticated execution grants are intentional, and each RPC checks the
caller's group ownership. The initial migration and its index follow-up were
applied to project `tilmizo` on 2026-10-04.

## Phase 4 group resources

Phase 4 is backend-only. Apply the versioned
`phase_4_resources_backend` migration after all Phase 3 migrations, then deploy
the `resource-upload`, `resource-delete`, and `resource-storage-cleanup` Edge
Functions. No Flutter resource feature is included in this phase.

Phase 4 intentionally stays on the Supabase Free plan. The migration creates one
private `group-resources` bucket with the platform's fixed 50 MB upload ceiling;
uploaded MP4 resources are therefore capped at 50 MB rather than the originally
planned 100 MB. It never creates a public file URL.

The public `resources` table is read-only through the Data API. Teachers create
external links with `create_external_resource`, edit metadata with
`update_resource_metadata`, and use the Edge Functions for uploaded-file
lifecycle and deletion. Approved students receive read and authenticated
download access dynamically through their current approved group session, so a
newly approved student can read resources created before they joined.

Uploaded content is immutable. `resource-upload` accepts three JSON actions:

- `reserve` validates the active owned group, optional session, declared file
  metadata, type limit, and locked teacher quota, then returns a two-hour signed
  upload token for a unique object path. Files above 6 MB should use Supabase's
  resumable TUS upload endpoint.
- `finalize` reads the object metadata and leading bytes from Storage, validates
  the actual size and file signature, and atomically creates the resource.
- `cancel` hides the pending upload immediately. Its quota reservation remains
  until the signed/resumable upload lifetime has elapsed, preventing a cancelled
  token from bypassing the configured quota.

`resource-delete` removes the resource from readers transactionally and then
deletes its object. Failed object deletions remain charged to the teacher and
are retried by `resource-storage-cleanup`. Archived groups remain readable but
all resource mutations require an active owned group.

### Cleanup configuration

Generate one high-entropy cleanup secret and set the same value in both places:

1. Deploy `resource-storage-cleanup` with `RESOURCE_CLEANUP_SECRET` as an Edge
   Function secret.
2. In Vault, create `resource_cleanup_secret` containing that value and
   `telmizo_project_url` containing `https://trmkevgtjdbvbzyknaih.supabase.co`.

The migration installs a 15-minute Cron job. It remains a no-op until both Vault
entries exist, so secrets never need to be committed. A second daily Cron job
reconciles the database quota ledger from resources, outstanding reservations,
and pending deletion jobs.

The configurable default product plan is stored in
`private.resource_plans`: 1 GB per teacher, 25 MB for PDF/general files, 10 MB
for images, and 50 MB for MP4. The Free plan's 1 GB file-storage allowance is
shared by the entire Supabase project, so it can become the effective ceiling
before an individual teacher reaches 1 GB. Assign future plan overrides through
`private.teacher_resource_plans`; do not hard-code subscription limits in a
client.

Authenticated teachers can call `get_my_resource_storage_usage` without any
arguments to display the current plan, committed and reserved bytes, combined
usage, remaining bytes, usage percentage, and per-type limits. The RPC always
derives the account from `auth.uid()` and does not accept a teacher ID.

### Teacher resource screen contract

- List a group's resources by selecting from `public.resources` with
  `group_id = <selected group id>`, ordered by `created_at` descending. The
  explicit `SELECT` grant and row-level policy limit results to the teacher's
  own groups; students see only resources in their currently approved groups.
  The table includes `type`, optional `session_id`, file metadata, and
  `external_url`, so search and type/session filters need no additional RPC.
- The type picker has exactly six backend values: `pdf`, `image`, `file`,
  `uploaded_video`, `external_link`, and `video_link`. The first four use the
  `resource-upload` reserve/upload/finalize flow; the link types use
  `create_external_resource`. Read per-type byte limits from
  `get_my_resource_storage_usage`, not from design mockups. The default Free
  limits are 25 MB PDF/file, 10 MB image, and 50 MB MP4.
- Delete by invoking `resource-delete` with a JSON body containing
  `resource_id` and the caller's access token. Only the active group's owner
  can delete. A successful response is either `200` with
  `cleanup_pending: false` or `202` with `cleanup_pending: true`; both mean the
  resource is no longer visible. The latter means object cleanup and quota
  release will be retried asynchronously. Do not delete table rows or Storage
  objects directly from a client.
- The backend has no draft, pinned-resource, notification, offline-access, or
  copy-protection feature. Resource creation publishes immediately to approved
  students; private Storage access must not be described as DRM.

After deployment, verify an authorized teacher reserve/upload/finalize/delete
cycle, an approved-student authenticated download, rejected cross-group access,
cancelled-upload cleanup, and exact quota boundaries. Run the database Security
and Performance Advisors after the migration.

## Private profile avatars

Teacher and student profile photos use the private `profile-avatars` bucket.
Each authenticated account owns exactly one object at `<user-id>/avatar` and
may create or overwrite only that path. The bucket accepts JPEG, PNG, and WebP
images up to 5 MB.

After every successful upload or upsert, call `set_my_profile_avatar()` without
arguments. The RPC derives the account from `auth.uid()`, confirms that the
authenticated caller owns the expected object, and stores its object path in
`profiles.avatar_url`. Direct client updates to `avatar_url` are revoked.

Downloads must use the authenticated Storage API. Owners can always load their
own photo; other signed-in users can load it only when the existing profile RLS
already permits them to read that profile. No public URL or delete policy is
created. Avatar bytes do not count against the teacher resource ledger, but do
use the Supabase project's shared Free-plan Storage allowance.

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
- Phase 1 treated every authenticated user as a teacher. Phase 2 authorizes
  teacher actions through group ownership and student actions through an
  approved membership/session; it does not yet add a global account-role
  system.
- Invite codes are nullable, case-sensitive, and not generated by the database.
