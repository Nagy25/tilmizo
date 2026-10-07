begin;

-- Existing plans continue to use their configured calendar day.
alter table public.monthly_payment_plans
  add column due_mode text not null default 'fixed_day'
    constraint monthly_payment_plans_due_mode_valid
    check (due_mode in ('fixed_day', 'join_day'));

-- One monthly obligation per active student. In join-day mode the recurring
-- day comes from that student's original group membership joined_at in Cairo.
-- Existing obligation rows retain their due_on snapshot when the mode changes.
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
      private.monthly_payment_due_on(
        v_month,
        case plan.due_mode
          when 'join_day' then
            extract(day from membership.joined_at at time zone 'Africa/Cairo')::integer
          else plan.due_day
        end
      ),
      case
        -- Approval after the student's chosen day is never retroactive.
        when p_student_id is not null then v_today
        -- The first month of a newly started plan is never retroactive.
        when plan.started_month = v_month then
          (plan.created_at at time zone 'Africa/Cairo')::date
        else v_month
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

create function public.configure_monthly_payment_plan(
  p_group_id uuid,
  p_amount numeric,
  p_due_day integer,
  p_due_mode text
)
returns public.monthly_payment_plans
language plpgsql security definer set search_path = ''
as $$
declare
  v_plan public.monthly_payment_plans%rowtype;
  v_suspended boolean;
  v_due_day integer;
begin
  perform private.assert_owned_payment_group(p_group_id, false);
  if p_amount is null or p_amount <= 0 or p_amount > 9999999999.99
    or round(p_amount, 2) <> p_amount then
    raise exception using errcode = '22023',
      message = 'A positive EGP amount with two decimal places is required';
  end if;
  if p_due_mode not in ('fixed_day', 'join_day') or p_due_mode is null then
    raise exception using errcode = '22023',
      message = 'A valid monthly due mode is required';
  end if;
  if p_due_mode = 'fixed_day' and
    (p_due_day is null or p_due_day not between 1 and 31) then
    raise exception using errcode = '22023',
      message = 'A monthly due day from 1 through 31 is required';
  end if;
  if p_due_mode = 'join_day' and p_due_day is not null then
    raise exception using errcode = '22023',
      message = 'Join-day plans must not specify a fixed due day';
  end if;
  v_due_day := case when p_due_mode = 'join_day' then 1 else p_due_day end;

  select owned_group.is_suspended into v_suspended
  from public.groups as owned_group where owned_group.id = p_group_id;

  select * into v_plan
  from public.monthly_payment_plans as plan
  where plan.group_id = p_group_id and plan.stopped_at is null
  for update;

  if found then
    update public.monthly_payment_plans as plan
    set amount = p_amount, due_day = v_due_day, due_mode = p_due_mode
    where plan.id = v_plan.id
    returning * into v_plan;
  else
    if v_suspended then
      raise exception using errcode = '42501',
        message = 'A suspended group cannot start a new payment plan';
    end if;
    insert into public.monthly_payment_plans (
      group_id, amount, due_day, due_mode, started_month, created_by
    ) values (
      p_group_id, p_amount, v_due_day, p_due_mode,
      private.current_cairo_month(), (select auth.uid())
    ) returning * into v_plan;
    perform private.generate_monthly_payment_obligations(p_group_id);
  end if;

  return v_plan;
end;
$$;

-- Preserve the previous RPC contract for older clients: an explicit numeric
-- day always selects fixed-day mode. The two-argument RPC remains amount-only.
create or replace function public.configure_monthly_payment_plan(
  p_group_id uuid,
  p_amount numeric,
  p_due_day integer
)
returns public.monthly_payment_plans
language sql security definer set search_path = ''
as $$
  select public.configure_monthly_payment_plan(
    p_group_id, p_amount, p_due_day, 'fixed_day'
  );
$$;

revoke all on function public.configure_monthly_payment_plan(
  uuid, numeric, integer, text
) from public, anon, authenticated;
grant execute on function public.configure_monthly_payment_plan(
  uuid, numeric, integer, text
) to authenticated;

commit;
