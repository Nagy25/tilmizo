-- Run in the Supabase SQL editor. Fixture writes are rolled back.
begin;

do $$
declare
  v_group_id uuid;
  v_teacher_id uuid;
  v_student_id uuid;
  v_joined_at timestamptz;
  v_month date := private.current_cairo_month();
  v_today date := (now() at time zone 'Africa/Cairo')::date;
  v_due_on date;
begin
  select owned_group.id, owned_group.teacher_id, membership.student_id,
    membership.joined_at
  into v_group_id, v_teacher_id, v_student_id, v_joined_at
  from public.groups as owned_group
  join public.group_memberships as membership
    on membership.group_id = owned_group.id
  where owned_group.is_active and not owned_group.is_suspended
    and membership.status = 'active'
    and not exists (
      select 1 from public.monthly_payment_plans as plan
      where plan.group_id = owned_group.id and plan.stopped_at is null
    )
    and not exists (
      select 1 from public.payment_obligations as obligation
      where obligation.group_id = owned_group.id
        and obligation.source_type = 'monthly'
        and obligation.period_month = v_month
    )
  limit 1;
  if v_group_id is null then
    raise exception 'An active group/student fixture without a plan is required';
  end if;
  perform set_config('request.jwt.claim.sub', v_teacher_id::text, true);

  begin
    perform public.configure_monthly_payment_plan(
      v_group_id, 100.00, 5, 'join_day'
    );
    raise exception 'Join-day plan accepted a fixed day';
  exception when invalid_parameter_value then null;
  end;

  perform public.configure_monthly_payment_plan(
    v_group_id, 100.00, null, 'join_day'
  );
  if not exists (
    select 1 from public.monthly_payment_plans
    where group_id = v_group_id and stopped_at is null
      and due_mode = 'join_day' and due_day = 1
  ) then
    raise exception 'Join-day plan was not saved';
  end if;
  select due_on into v_due_on from public.payment_obligations
  where group_id = v_group_id and student_id = v_student_id
    and source_type = 'monthly' and period_month = v_month;
  if v_due_on is distinct from greatest(
    private.monthly_payment_due_on(
      v_month,
      extract(day from v_joined_at at time zone 'Africa/Cairo')::integer
    ),
    v_today
  ) then
    raise exception 'Join-day obligation has wrong due date: %', v_due_on;
  end if;

  perform public.configure_monthly_payment_plan(
    v_group_id, 125.00, 15, 'fixed_day'
  );
  if not exists (
    select 1 from public.payment_obligations
    where group_id = v_group_id and student_id = v_student_id
      and source_type = 'monthly' and period_month = v_month
      and amount = 100.00 and due_on = v_due_on
  ) then
    raise exception 'Changing due mode altered an existing obligation';
  end if;
  perform public.configure_monthly_payment_plan(
    v_group_id, 150.00, null, 'join_day'
  );
  perform public.configure_monthly_payment_plan(v_group_id, 160.00);
  if not exists (
    select 1 from public.monthly_payment_plans
    where group_id = v_group_id and stopped_at is null
      and due_mode = 'join_day' and amount = 160.00
  ) then
    raise exception 'Legacy two-argument RPC did not preserve join-day mode';
  end if;
  perform public.configure_monthly_payment_plan(v_group_id, 175.00, 10);
  if not exists (
    select 1 from public.monthly_payment_plans
    where group_id = v_group_id and stopped_at is null
      and due_mode = 'fixed_day' and due_day = 10 and amount = 175.00
  ) then
    raise exception 'Legacy three-argument RPC did not select fixed-day mode';
  end if;

  if has_function_privilege('anon',
      'public.configure_monthly_payment_plan(uuid,numeric,integer,text)',
      'EXECUTE')
    or not has_function_privilege('authenticated',
      'public.configure_monthly_payment_plan(uuid,numeric,integer,text)',
      'EXECUTE') then
    raise exception 'Join-day RPC execution grants are incorrect';
  end if;
  raise notice 'Monthly join-day smoke test passed';
end;
$$;

rollback;
