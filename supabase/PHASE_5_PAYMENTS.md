# Phase 5 payment-record backend

Telmizo records expected EGP amounts and teacher-confirmed full payments. It
does not transfer money. All amounts have two decimal places.

## Read API

Authenticated clients can select `monthly_payment_plans`,
`session_payment_items`, `one_time_payment_items`, `payment_obligations`, and
`payment_receipts`. RLS limits plan/item rows to the owning teacher and
obligation/receipt rows to the owning teacher or the student named on the
obligation. A student's own history remains readable after leaving the group.
Clients cannot directly insert, update, or delete these rows.

`payment_obligations` is the student-facing list. Filter by `group_id` and/or
`student_id`, and normally show `status in ('unpaid', 'paid')`. Each row contains
the amount/title snapshot. `source_type` is `monthly`, `session`, or `one_time`;
`period_month` is the first Cairo-calendar day for monthly rows. A `void` row
is historical and should not be presented as an amount currently due. A paid
row has one active `payment_receipts` row with the method and timestamp;
voided receipts remain for audit.

`groups.is_active = false` means archived. `groups.is_suspended = true` pauses
new sessions and obligations but retains already-created sessions and payment
history. Existing unpaid obligations may still be marked paid while suspended.

## Teacher write RPCs

All inputs use named RPC parameters and the teacher is derived from the JWT.

| RPC | Required parameters | Optional parameters | Returns |
| --- | --- | --- | --- |
| `configure_monthly_payment_plan` | `p_group_id`, `p_amount`, `p_due_day`, `p_due_mode` | — | plan row |
| `stop_monthly_payment_plan` | `p_group_id` | — | stopped plan row |
| `set_group_suspension` | `p_group_id`, `p_suspended` | — | group row |
| `attach_session_payment` | `p_session_id`, `p_amount` | — | session payment item |
| `create_one_time_group_payment` | `p_group_id`, `p_title`, `p_amount` | `p_description` | one-time item |
| `mark_payment_paid` | `p_obligation_id`, `p_method` | — | receipt row |
| `void_paid_payment` | `p_receipt_id` | — | corrected obligation row |
| `create_manual_session_with_payment` | `p_group_id`, `p_starts_at`, `p_ends_at`, `p_location_type` | `p_physical_location`, `p_meeting_link`, `p_notes`, `p_payment_amount` | JSON with `session` and `payment_item` |

`p_method` is one of `cash`, `instapay`, `wallet`, `bank_transfer`, or `other`.
For a monthly plan, `p_due_mode` is `fixed_day` or `join_day`. In `fixed_day`
mode, `p_due_day` must be an integer from 1 through 31. Day 1 means the first
day of each Cairo-calendar month. In `join_day` mode, pass `p_due_day: null`;
each student's recurring due day is the Cairo day of their membership's
`joined_at` timestamp. Days beyond the end of shorter months clamp to the last
day. Existing plans default to `fixed_day` and day 1. The legacy
three-argument RPC sets `fixed_day` mode, while the legacy two-argument RPC
changes amount only and preserves the existing mode and day.

The original `create_manual_class_session` RPC remains available, now checking
suspension. The optional-payment RPC creates the session and its amount in one
transaction. For an existing manually or automatically generated session, use
`attach_session_payment` once. Uploaded resources are unrelated to payments.

Changing a monthly plan's amount, due mode, or day affects only newly generated months.
The current month's obligation retains its original amount and due date. A
student approved after the configured day is due on their approval day for that
first month. Starting a plan after its configured day similarly makes the
first month due on the activation day rather than retroactively. Stopping
it does not remove existing obligations. A daily Cron job generates only the
current Cairo month, idempotently. On resumption, the current month is
generated if absent, without backfilling suspended months. Joining students
receive the current month and future paid-session obligations, not earlier
one-time amounts or past sessions.

Cancelling a session voids its unpaid obligations. A paid mark remains visible
until the teacher voids that receipt; if the session was cancelled, the
obligation then becomes `void` rather than `unpaid`.

## Verification

Run the four rollback-only SQL smoke scripts in `supabase/tests/` against a
project with an active group and active student. The lifecycle script also
requires that group to have no active monthly plan. Both scripts leave all
fixture writes rolled back.
