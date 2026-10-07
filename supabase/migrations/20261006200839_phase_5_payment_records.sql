begin;

do $$
begin
  if to_regclass('public.groups') is null
    or to_regclass('public.group_memberships') is null
    or to_regclass('public.class_sessions') is null then
    raise exception 'Phase 5 requires the Phase 1-4 schema';
  end if;
end;
$$;

-- is_active continues to mean "not archived" for existing clients.
alter table public.groups
  add column is_suspended boolean not null default false;

create table public.monthly_payment_plans (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  started_month date not null,
  stopped_at timestamptz,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, group_id),
  constraint monthly_payment_plans_month_start check (
    extract(day from started_month) = 1
  )
);

create unique index monthly_payment_plans_one_active_per_group_idx
  on public.monthly_payment_plans (group_id) where stopped_at is null;
create index monthly_payment_plans_group_created_idx
  on public.monthly_payment_plans (group_id, created_at desc);

create table public.session_payment_items (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null,
  group_id uuid not null,
  amount numeric(12,2) not null check (amount > 0),
  cancelled_at timestamptz,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (id, group_id),
  constraint session_payment_items_session_group_fkey
    foreign key (session_id, group_id)
    references public.class_sessions (id, group_id) on delete restrict
);

create unique index session_payment_items_one_active_per_session_idx
  on public.session_payment_items (session_id) where cancelled_at is null;
create index session_payment_items_group_created_idx
  on public.session_payment_items (group_id, created_at desc);

create table public.one_time_payment_items (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete restrict,
  title text not null check (btrim(title) <> '' and char_length(title) <= 200),
  description text check (
    description is null or char_length(description) <= 5000
  ),
  amount numeric(12,2) not null check (amount > 0),
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (id, group_id)
);

create index one_time_payment_items_group_created_idx
  on public.one_time_payment_items (group_id, created_at desc);

create table public.payment_obligations (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null,
  student_id uuid not null,
  source_type text not null check (
    source_type in ('monthly', 'session', 'one_time')
  ),
  monthly_plan_id uuid,
  session_payment_id uuid,
  one_time_item_id uuid,
  period_month date,
  title text not null check (btrim(title) <> '' and char_length(title) <= 200),
  description text check (
    description is null or char_length(description) <= 5000
  ),
  amount numeric(12,2) not null check (amount > 0),
  currency text not null default 'EGP' check (currency = 'EGP'),
  due_on date not null,
  status text not null default 'unpaid'
    check (status in ('unpaid', 'paid', 'void')),
  voided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payment_obligations_membership_fkey
    foreign key (group_id, student_id)
    references public.group_memberships (group_id, student_id)
    on delete restrict,
  constraint payment_obligations_monthly_plan_fkey
    foreign key (monthly_plan_id, group_id)
    references public.monthly_payment_plans (id, group_id)
    on delete restrict,
  constraint payment_obligations_session_payment_fkey
    foreign key (session_payment_id, group_id)
    references public.session_payment_items (id, group_id)
    on delete restrict,
  constraint payment_obligations_one_time_item_fkey
    foreign key (one_time_item_id, group_id)
    references public.one_time_payment_items (id, group_id)
    on delete restrict,
  constraint payment_obligations_source_valid check (
    (source_type = 'monthly' and monthly_plan_id is not null
      and period_month is not null
      and extract(day from period_month) = 1
      and session_payment_id is null and one_time_item_id is null)
    or
    (source_type = 'session' and session_payment_id is not null
      and monthly_plan_id is null and one_time_item_id is null
      and period_month is null)
    or
    (source_type = 'one_time' and one_time_item_id is not null
      and monthly_plan_id is null and session_payment_id is null
      and period_month is null)
  ),
  constraint payment_obligations_voided_valid check (
    (status = 'void' and voided_at is not null)
    or (status <> 'void' and voided_at is null)
  )
);

create unique index payment_obligations_monthly_unique_idx
  on public.payment_obligations (group_id, student_id, period_month)
  where source_type = 'monthly';
create unique index payment_obligations_session_unique_idx
  on public.payment_obligations (session_payment_id, student_id)
  where source_type = 'session';
create unique index payment_obligations_one_time_unique_idx
  on public.payment_obligations (one_time_item_id, student_id)
  where source_type = 'one_time';
create index payment_obligations_group_student_created_idx
  on public.payment_obligations (group_id, student_id, created_at desc);
create index payment_obligations_student_due_idx
  on public.payment_obligations (student_id, due_on desc);
create index payment_obligations_group_status_due_idx
  on public.payment_obligations (group_id, status, due_on);

create table public.payment_receipts (
  id uuid primary key default gen_random_uuid(),
  obligation_id uuid not null references public.payment_obligations (id)
    on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  method text not null check (
    method in ('cash', 'instapay', 'wallet', 'bank_transfer', 'other')
  ),
  recorded_by uuid not null references public.profiles (id) on delete restrict,
  recorded_at timestamptz not null default now(),
  voided_by uuid references public.profiles (id) on delete restrict,
  voided_at timestamptz,
  constraint payment_receipts_voided_valid check (
    (voided_at is null and voided_by is null)
    or (voided_at is not null and voided_by is not null)
  )
);

create unique index payment_receipts_one_active_idx
  on public.payment_receipts (obligation_id) where voided_at is null;
create index payment_receipts_obligation_recorded_idx
  on public.payment_receipts (obligation_id, recorded_at desc);
create index payment_receipts_recorded_by_idx
  on public.payment_receipts (recorded_by);
create index payment_receipts_voided_by_idx
  on public.payment_receipts (voided_by) where voided_by is not null;

create trigger set_monthly_payment_plans_updated_at
  before update on public.monthly_payment_plans
  for each row execute function private.set_updated_at();
create trigger set_payment_obligations_updated_at
  before update on public.payment_obligations
  for each row execute function private.set_updated_at();

alter table public.monthly_payment_plans enable row level security;
alter table public.session_payment_items enable row level security;
alter table public.one_time_payment_items enable row level security;
alter table public.payment_obligations enable row level security;
alter table public.payment_receipts enable row level security;

revoke all on table public.monthly_payment_plans,
  public.session_payment_items, public.one_time_payment_items,
  public.payment_obligations, public.payment_receipts
  from public, anon, authenticated;
grant select on table public.monthly_payment_plans,
  public.session_payment_items, public.one_time_payment_items,
  public.payment_obligations, public.payment_receipts
  to authenticated;
grant all on table public.monthly_payment_plans,
  public.session_payment_items, public.one_time_payment_items,
  public.payment_obligations, public.payment_receipts
  to service_role;

create policy "Teachers read monthly payment plans"
on public.monthly_payment_plans for select to authenticated
using (private.owns_group(group_id));
create policy "Teachers read session payment items"
on public.session_payment_items for select to authenticated
using (private.owns_group(group_id));
create policy "Teachers read one-time payment items"
on public.one_time_payment_items for select to authenticated
using (private.owns_group(group_id));
create policy "Teachers and students read own payment obligations"
on public.payment_obligations for select to authenticated
using (
  private.owns_group(group_id)
  or student_id = (select auth.uid())
);
create policy "Teachers and students read own payment receipts"
on public.payment_receipts for select to authenticated
using (
  exists (
    select 1 from public.payment_obligations as obligation
    where obligation.id = payment_receipts.obligation_id
      and (
        private.owns_group(obligation.group_id)
        or obligation.student_id = (select auth.uid())
      )
  )
);

create function private.current_cairo_month()
returns date
language sql stable security invoker set search_path = ''
as $$
  select date_trunc('month', now() at time zone 'Africa/Cairo')::date;
$$;

create function private.assert_owned_payment_group(
  p_group_id uuid,
  p_require_unsuspended boolean default true
)
returns void
language plpgsql stable security definer set search_path = ''
as $$
begin
  if (select auth.uid()) is null or not exists (
    select 1 from public.groups as owned_group
    where owned_group.id = p_group_id
      and owned_group.teacher_id = (select auth.uid())
      and owned_group.is_active
      and (not p_require_unsuspended or not owned_group.is_suspended)
  ) then
    raise exception using errcode = '42501',
      message = 'An active owned group is required';
  end if;
end;
$$;

-- Idempotent for Cron, plan creation, resume, and new membership approval.
-- Only the current Cairo month is ever generated: suspended months are not
-- backfilled on resume.
create function private.generate_monthly_payment_obligations(
  p_group_id uuid default null,
  p_student_id uuid default null
)
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_month date := private.current_cairo_month();
  v_inserted integer;
begin
  insert into public.payment_obligations (
    group_id, student_id, source_type, monthly_plan_id, period_month,
    title, amount, due_on
  )
  select
    plan.group_id,
    membership.student_id,
    'monthly',
    plan.id,
    v_month,
    'Monthly payment',
    plan.amount,
    v_month
  from public.monthly_payment_plans as plan
  join public.groups as owned_group on owned_group.id = plan.group_id
  join public.group_memberships as membership
    on membership.group_id = plan.group_id
  where plan.stopped_at is null
    and plan.started_month <= v_month
    and owned_group.is_active
    and not owned_group.is_suspended
    and membership.status = 'active'
    and (p_group_id is null or plan.group_id = p_group_id)
    and (p_student_id is null or membership.student_id = p_student_id)
  on conflict (group_id, student_id, period_month)
    where source_type = 'monthly' do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

create function private.generate_future_session_payment_obligations(
  p_group_id uuid,
  p_student_id uuid
)
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_inserted integer;
begin
  insert into public.payment_obligations (
    group_id, student_id, source_type, session_payment_id,
    title, amount, due_on
  )
  select
    item.group_id,
    p_student_id,
    'session',
    item.id,
    'Session payment',
    item.amount,
    (session.starts_at at time zone 'Africa/Cairo')::date
  from public.session_payment_items as item
  join public.class_sessions as session on session.id = item.session_id
  join public.groups as owned_group on owned_group.id = item.group_id
  where item.group_id = p_group_id
    and item.cancelled_at is null
    and session.status = 'scheduled'
    and session.starts_at > now()
    and owned_group.is_active
    and not owned_group.is_suspended
    and exists (
      select 1 from public.group_memberships as membership
      where membership.group_id = p_group_id
        and membership.student_id = p_student_id
        and membership.status = 'active'
    )
  on conflict (session_payment_id, student_id)
    where source_type = 'session' do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

create function private.seed_newly_approved_member_payments()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.status <> 'active' then
    return new;
  end if;
  if tg_op = 'UPDATE' then
    if old.status = 'active' then
      return new;
    end if;
  end if;
  if tg_op = 'INSERT' or tg_op = 'UPDATE' then
    perform private.generate_monthly_payment_obligations(
      new.group_id, new.student_id
    );
    perform private.generate_future_session_payment_obligations(
      new.group_id, new.student_id
    );
  end if;
  return new;
end;
$$;

create trigger seed_newly_approved_member_payments
  after insert or update of status on public.group_memberships
  for each row execute function private.seed_newly_approved_member_payments();

-- Serializes new obligations against suspension and session cancellation.
create function private.guard_new_payment_obligation()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_group public.groups%rowtype;
  v_session_status text;
  v_item_cancelled_at timestamptz;
begin
  select * into v_group
  from public.groups where id = new.group_id for share;
  if not found or not v_group.is_active or v_group.is_suspended then
    raise exception using errcode = '42501',
      message = 'The group cannot receive new payment records';
  end if;

  if new.source_type = 'session' then
    select session.status, item.cancelled_at
    into v_session_status, v_item_cancelled_at
    from public.session_payment_items as item
    join public.class_sessions as session on session.id = item.session_id
    where item.id = new.session_payment_id
    for share of item, session;
    if not found or v_session_status = 'cancelled'
      or v_item_cancelled_at is not null then
      raise exception using errcode = '22023',
        message = 'A cancelled session cannot receive a payment record';
    end if;
  end if;

  return new;
end;
$$;

create trigger guard_new_payment_obligation
  before insert on public.payment_obligations
  for each row execute function private.guard_new_payment_obligation();

create function private.void_cancelled_session_payments()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.status = 'cancelled' and old.status is distinct from 'cancelled' then
    update public.session_payment_items
    set cancelled_at = now()
    where session_id = new.id and cancelled_at is null;

    update public.payment_obligations as obligation
    set status = 'void', voided_at = now()
    from public.session_payment_items as item
    where item.session_id = new.id
      and obligation.session_payment_id = item.id
      and obligation.status = 'unpaid';
  end if;
  return new;
end;
$$;

create trigger void_cancelled_session_payments
  after update of status on public.class_sessions
  for each row execute function private.void_cancelled_session_payments();

revoke all on function private.current_cairo_month(),
  private.assert_owned_payment_group(uuid, boolean),
  private.generate_monthly_payment_obligations(uuid, uuid),
  private.generate_future_session_payment_obligations(uuid, uuid),
  private.seed_newly_approved_member_payments(),
  private.guard_new_payment_obligation(),
  private.void_cancelled_session_payments()
  from public, anon, authenticated;

create function public.set_group_suspension(
  p_group_id uuid,
  p_suspended boolean
)
returns public.groups
language plpgsql security definer set search_path = ''
as $$
declare
  v_group public.groups%rowtype;
  v_entry record;
begin
  if p_suspended is null then
    raise exception using errcode = '22023',
      message = 'A suspension state is required';
  end if;

  update public.groups as owned_group
  set is_suspended = p_suspended
  where owned_group.id = p_group_id
    and owned_group.teacher_id = (select auth.uid())
    and owned_group.is_active
  returning * into v_group;

  if not found then
    raise exception using errcode = '42501',
      message = 'An active owned group is required';
  end if;

  if not p_suspended then
    perform private.generate_monthly_payment_obligations(p_group_id);
    for v_entry in
      select entry.id from public.group_schedule_entries as entry
      where entry.group_id = p_group_id and entry.is_active
    loop
      perform private.fill_class_sessions(v_entry.id);
    end loop;
  end if;

  return v_group;
end;
$$;

create function public.configure_monthly_payment_plan(
  p_group_id uuid,
  p_amount numeric
)
returns public.monthly_payment_plans
language plpgsql security definer set search_path = ''
as $$
declare
  v_plan public.monthly_payment_plans%rowtype;
  v_suspended boolean;
begin
  perform private.assert_owned_payment_group(p_group_id, false);
  if p_amount is null or p_amount <= 0 or p_amount > 9999999999.99
    or round(p_amount, 2) <> p_amount then
    raise exception using errcode = '22023',
      message = 'A positive EGP amount with two decimal places is required';
  end if;

  select owned_group.is_suspended into v_suspended
  from public.groups as owned_group where owned_group.id = p_group_id;

  select * into v_plan
  from public.monthly_payment_plans as plan
  where plan.group_id = p_group_id and plan.stopped_at is null
  for update;

  if found then
    update public.monthly_payment_plans as plan
    set amount = p_amount
    where plan.id = v_plan.id
    returning * into v_plan;
  else
    if v_suspended then
      raise exception using errcode = '42501',
        message = 'A suspended group cannot start a new payment plan';
    end if;
    insert into public.monthly_payment_plans (
      group_id, amount, started_month, created_by
    ) values (
      p_group_id, p_amount, private.current_cairo_month(), (select auth.uid())
    ) returning * into v_plan;
    perform private.generate_monthly_payment_obligations(p_group_id);
  end if;

  return v_plan;
end;
$$;

create function public.stop_monthly_payment_plan(p_group_id uuid)
returns public.monthly_payment_plans
language plpgsql security definer set search_path = ''
as $$
declare
  v_plan public.monthly_payment_plans%rowtype;
begin
  perform private.assert_owned_payment_group(p_group_id, false);
  update public.monthly_payment_plans as plan
  set stopped_at = now()
  where plan.group_id = p_group_id and plan.stopped_at is null
  returning * into v_plan;
  if not found then
    raise exception using errcode = '22023',
      message = 'No active monthly payment plan exists';
  end if;
  return v_plan;
end;
$$;

create function public.attach_session_payment(
  p_session_id uuid,
  p_amount numeric
)
returns public.session_payment_items
language plpgsql security definer set search_path = ''
as $$
declare
  v_session public.class_sessions%rowtype;
  v_item public.session_payment_items%rowtype;
begin
  select * into v_session
  from public.class_sessions as session
  where session.id = p_session_id
  for update;
  if not found or v_session.status = 'cancelled' then
    raise exception using errcode = '22023',
      message = 'An uncancelled session is required';
  end if;
  perform private.assert_owned_payment_group(v_session.group_id);
  if p_amount is null or p_amount <= 0 or p_amount > 9999999999.99
    or round(p_amount, 2) <> p_amount then
    raise exception using errcode = '22023',
      message = 'A positive EGP amount with two decimal places is required';
  end if;

  insert into public.session_payment_items (
    session_id, group_id, amount, created_by
  ) values (
    p_session_id, v_session.group_id, p_amount, (select auth.uid())
  ) returning * into v_item;

  insert into public.payment_obligations (
    group_id, student_id, source_type, session_payment_id,
    title, amount, due_on
  )
  select
    v_session.group_id, membership.student_id, 'session', v_item.id,
    'Session payment', p_amount,
    (v_session.starts_at at time zone 'Africa/Cairo')::date
  from public.group_memberships as membership
  where membership.group_id = v_session.group_id
    and membership.status = 'active';

  return v_item;
end;
$$;

create function public.create_one_time_group_payment(
  p_group_id uuid,
  p_title text,
  p_amount numeric,
  p_description text default null
)
returns public.one_time_payment_items
language plpgsql security definer set search_path = ''
as $$
declare
  v_item public.one_time_payment_items%rowtype;
begin
  perform private.assert_owned_payment_group(p_group_id);
  if p_title is null or btrim(p_title) = ''
    or char_length(btrim(p_title)) > 200 then
    raise exception using errcode = '22023',
      message = 'A title of at most 200 characters is required';
  end if;
  if p_description is not null and char_length(p_description) > 5000 then
    raise exception using errcode = '22023',
      message = 'The description is too long';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > 9999999999.99
    or round(p_amount, 2) <> p_amount then
    raise exception using errcode = '22023',
      message = 'A positive EGP amount with two decimal places is required';
  end if;

  insert into public.one_time_payment_items (
    group_id, title, description, amount, created_by
  ) values (
    p_group_id, btrim(p_title), nullif(btrim(p_description), ''),
    p_amount, (select auth.uid())
  ) returning * into v_item;

  insert into public.payment_obligations (
    group_id, student_id, source_type, one_time_item_id,
    title, description, amount, due_on
  )
  select
    p_group_id, membership.student_id, 'one_time', v_item.id,
    v_item.title, v_item.description, v_item.amount,
    (now() at time zone 'Africa/Cairo')::date
  from public.group_memberships as membership
  where membership.group_id = p_group_id
    and membership.status = 'active';

  return v_item;
end;
$$;

create function public.mark_payment_paid(
  p_obligation_id uuid,
  p_method text
)
returns public.payment_receipts
language plpgsql security definer set search_path = ''
as $$
declare
  v_obligation public.payment_obligations%rowtype;
  v_receipt public.payment_receipts%rowtype;
begin
  if p_method is null or p_method not in (
    'cash', 'instapay', 'wallet', 'bank_transfer', 'other'
  ) then
    raise exception using errcode = '22023',
      message = 'A valid payment method is required';
  end if;

  select * into v_obligation
  from public.payment_obligations as obligation
  where obligation.id = p_obligation_id
  for update;
  if not found then
    raise exception using errcode = '42501',
      message = 'The payment record is unavailable';
  end if;
  perform private.assert_owned_payment_group(v_obligation.group_id, false);
  if v_obligation.status <> 'unpaid' then
    raise exception using errcode = '22023',
      message = 'Only an unpaid record may be marked paid';
  end if;

  insert into public.payment_receipts (
    obligation_id, amount, method, recorded_by
  ) values (
    v_obligation.id, v_obligation.amount, p_method, (select auth.uid())
  ) returning * into v_receipt;

  update public.payment_obligations
  set status = 'paid'
  where id = v_obligation.id;

  return v_receipt;
end;
$$;

create function public.void_paid_payment(p_receipt_id uuid)
returns public.payment_obligations
language plpgsql security definer set search_path = ''
as $$
declare
  v_obligation public.payment_obligations%rowtype;
  v_receipt public.payment_receipts%rowtype;
  v_cancelled_session boolean;
begin
  select obligation.*
  into v_obligation
  from public.payment_receipts as receipt
  join public.payment_obligations as obligation
    on obligation.id = receipt.obligation_id
  where receipt.id = p_receipt_id
  for update of obligation, receipt;

  if not found then
    raise exception using errcode = '42501',
      message = 'The paid record is unavailable';
  end if;
  select * into v_receipt
  from public.payment_receipts where id = p_receipt_id;
  perform private.assert_owned_payment_group(v_obligation.group_id, false);
  if v_receipt.voided_at is not null or v_obligation.status <> 'paid' then
    raise exception using errcode = '22023',
      message = 'Only an active paid mark may be voided';
  end if;

  update public.payment_receipts
  set voided_at = now(), voided_by = (select auth.uid())
  where id = p_receipt_id;

  select exists (
    select 1 from public.session_payment_items as item
    where item.id = v_obligation.session_payment_id
      and item.cancelled_at is not null
  ) into v_cancelled_session;

  update public.payment_obligations
  set status = case when v_cancelled_session then 'void' else 'unpaid' end,
      voided_at = case when v_cancelled_session then now() else null end
  where id = v_obligation.id
  returning * into v_obligation;

  return v_obligation;
end;
$$;

-- Preserve the existing manual-session RPC signature. The wrapper below adds
-- optional payment atomically for new callers.
create or replace function public.create_manual_class_session(
  p_group_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_location_type text,
  p_physical_location text default null,
  p_meeting_link text default null,
  p_notes text default null
)
returns public.class_sessions
language plpgsql security definer set search_path = ''
as $$
declare
  v_session public.class_sessions%rowtype;
begin
  perform private.assert_owned_payment_group(p_group_id);

  insert into public.class_sessions (
    group_id, starts_at, ends_at, location_type,
    physical_location, meeting_link, notes
  ) values (
    p_group_id, p_starts_at, p_ends_at, p_location_type,
    p_physical_location, p_meeting_link, p_notes
  ) returning * into v_session;

  return v_session;
end;
$$;

create function public.create_manual_session_with_payment(
  p_group_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_location_type text,
  p_physical_location text default null,
  p_meeting_link text default null,
  p_notes text default null,
  p_payment_amount numeric default null
)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_session public.class_sessions%rowtype;
  v_item public.session_payment_items%rowtype;
begin
  v_session := public.create_manual_class_session(
    p_group_id, p_starts_at, p_ends_at, p_location_type,
    p_physical_location, p_meeting_link, p_notes
  );
  if p_payment_amount is not null then
    v_item := public.attach_session_payment(v_session.id, p_payment_amount);
  end if;
  return jsonb_build_object(
    'session', to_jsonb(v_session),
    'payment_item', case
      when p_payment_amount is null then null else to_jsonb(v_item)
    end
  );
end;
$$;

-- The existing scheduler generates a 28-day window. Suspended groups keep
-- already-created sessions, but get no additional generated occurrences.
create or replace function private.fill_class_sessions(p_schedule_id uuid default null)
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Africa/Cairo')::date;
  v_inserted integer;
begin
  insert into public.class_sessions (
    group_id, schedule_entry_id, original_date,
    starts_at, ends_at, location_type, physical_location, meeting_link
  )
  select
    entry.group_id,
    entry.id,
    occurrence.day,
    occurrence.starts_at,
    occurrence.ends_at,
    entry.location_type,
    entry.physical_location,
    entry.meeting_link
  from public.group_schedule_entries as entry
  join public.groups as owned_group on owned_group.id = entry.group_id
  cross join lateral (
    select
      (v_today + day_offset) as day,
      (v_today + day_offset + entry.start_time) at time zone 'Africa/Cairo'
        as starts_at,
      (v_today + day_offset + entry.end_time) at time zone 'Africa/Cairo'
        as ends_at
    from generate_series(0, 27) as calendar(day_offset)
    where extract(isodow from v_today + day_offset)::smallint = entry.weekday
  ) as occurrence
  where owned_group.is_active
    and not owned_group.is_suspended
    and entry.is_active
    and (p_schedule_id is null or entry.id = p_schedule_id)
    and occurrence.starts_at > now()
    and occurrence.ends_at > occurrence.starts_at
  on conflict (schedule_entry_id, original_date)
    where schedule_entry_id is not null do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

-- Archiving clears the transient suspension marker without reviving billing.
create or replace function public.archive_group(p_group_id uuid)
returns public.groups
language plpgsql security definer set search_path = ''
as $$
declare
  v_group public.groups%rowtype;
begin
  update public.groups as owned_group
  set is_active = false, is_suspended = false
  where owned_group.id = p_group_id
    and owned_group.teacher_id = (select auth.uid())
  returning * into v_group;

  if not found then
    raise exception using errcode = '42501',
      message = 'An owned group is required';
  end if;
  return v_group;
end;
$$;

revoke all on function public.set_group_suspension(uuid, boolean),
  public.configure_monthly_payment_plan(uuid, numeric),
  public.stop_monthly_payment_plan(uuid),
  public.attach_session_payment(uuid, numeric),
  public.create_one_time_group_payment(uuid, text, numeric, text),
  public.mark_payment_paid(uuid, text),
  public.void_paid_payment(uuid),
  public.create_manual_session_with_payment(
    uuid, timestamptz, timestamptz, text, text, text, text, numeric
  ) from public, anon, authenticated;

grant execute on function public.set_group_suspension(uuid, boolean),
  public.configure_monthly_payment_plan(uuid, numeric),
  public.stop_monthly_payment_plan(uuid),
  public.attach_session_payment(uuid, numeric),
  public.create_one_time_group_payment(uuid, text, numeric, text),
  public.mark_payment_paid(uuid, text),
  public.void_paid_payment(uuid),
  public.create_manual_session_with_payment(
    uuid, timestamptz, timestamptz, text, text, text, text, numeric
  ) to authenticated;

-- 00:20 UTC is after the Cairo date boundary in both winter and summer.
-- Running daily catches missed first-of-month executions without backfilling.
select cron.schedule(
  'telmizo_phase5_monthly_payments',
  '20 0 * * *',
  'select private.generate_monthly_payment_obligations();'
);

commit;
