begin;

-- Existing plans retain their first-of-month due date. The configured day is
-- clamped to the last day of shorter months when obligations are generated.
alter table public.monthly_payment_plans
  add column due_day smallint not null default 1
    constraint monthly_payment_plans_due_day_valid
    check (due_day between 1 and 31);

create function private.monthly_payment_due_on(
  p_month date,
  p_due_day integer
)
returns date
language sql immutable security invoker set search_path = ''
as $$
  select least(
    p_month + (p_due_day - 1),
    (p_month + interval '1 month' - interval '1 day')::date
  );
$$;

revoke all on function private.monthly_payment_due_on(date, integer)
  from public, anon, authenticated;

-- Keep the existing signature for Cron, plan start/resume, and the membership
-- approval trigger. Each inserted obligation snapshots its actual due date.
create or replace function private.generate_monthly_payment_obligations(
  p_group_id uuid default null,
  p_student_id uuid default null
)
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_month date := private.current_cairo_month();
  v_today date := (now() at time zone 'Africa/Cairo')::date;
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
    greatest(
      private.monthly_payment_due_on(v_month, plan.due_day),
      case
        -- An approval after the selected day is due on the approval day,
        -- rather than already overdue at the moment the student joins.
        when p_student_id is not null then v_today
        -- A newly started plan also must not create retroactive current-month
        -- obligations if its selected day has already passed.
        when plan.started_month = v_month then
          (plan.created_at at time zone 'Africa/Cairo')::date
        else private.monthly_payment_due_on(v_month, plan.due_day)
      end
    )
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

-- The original two-argument RPC remains available and changes only amount.
-- This overload lets new clients explicitly set the recurring due day.
create function public.configure_monthly_payment_plan(
  p_group_id uuid,
  p_amount numeric,
  p_due_day integer
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
  if p_due_day is null or p_due_day not between 1 and 31 then
    raise exception using errcode = '22023',
      message = 'A monthly due day from 1 through 31 is required';
  end if;

  select owned_group.is_suspended into v_suspended
  from public.groups as owned_group where owned_group.id = p_group_id;

  select * into v_plan
  from public.monthly_payment_plans as plan
  where plan.group_id = p_group_id and plan.stopped_at is null
  for update;

  if found then
    update public.monthly_payment_plans as plan
    set amount = p_amount, due_day = p_due_day
    where plan.id = v_plan.id
    returning * into v_plan;
  else
    if v_suspended then
      raise exception using errcode = '42501',
        message = 'A suspended group cannot start a new payment plan';
    end if;
    insert into public.monthly_payment_plans (
      group_id, amount, due_day, started_month, created_by
    ) values (
      p_group_id, p_amount, p_due_day, private.current_cairo_month(),
      (select auth.uid())
    ) returning * into v_plan;
    perform private.generate_monthly_payment_obligations(p_group_id);
  end if;

  return v_plan;
end;
$$;

revoke all on function public.configure_monthly_payment_plan(
  uuid, numeric, integer
) from public, anon, authenticated;
grant execute on function public.configure_monthly_payment_plan(
  uuid, numeric, integer
) to authenticated;

commit;
