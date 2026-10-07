-- Run in the Supabase SQL editor. All fixture mutations roll back.
-- Requires an active group with an active student and no active monthly plan.
begin;

do $$
declare
  v_group_id uuid;
  v_teacher_id uuid;
  v_student_id uuid;
  v_month date := private.current_cairo_month();
  v_today date := (now() at time zone 'Africa/Cairo')::date;
  v_due_on date;
  v_inserted integer;
begin
  if private.monthly_payment_due_on(date '2028-02-01', 31)
      <> date '2028-02-29'
    or private.monthly_payment_due_on(date '2027-02-01', 31)
      <> date '2027-02-28'
    or private.monthly_payment_due_on(date '2027-04-01', 30)
      <> date '2027-04-30'
    or private.monthly_payment_due_on(date '2027-05-01', 1)
      <> date '2027-05-01' then
    raise exception 'Monthly due-day clamping failed';
  end if;

  select owned_group.id, owned_group.teacher_id, membership.student_id
  into v_group_id, v_teacher_id, v_student_id
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
    perform public.configure_monthly_payment_plan(v_group_id, 100.00, 0);
    raise exception 'Invalid due day 0 was accepted';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.configure_monthly_payment_plan(v_group_id, 100.00, 32);
    raise exception 'Invalid due day 32 was accepted';
  exception when invalid_parameter_value then null;
  end;

  perform public.configure_monthly_payment_plan(v_group_id, 100.00, 31);
  select due_on into v_due_on from public.payment_obligations
  where group_id = v_group_id and student_id = v_student_id
    and source_type = 'monthly' and period_month = v_month;
  if v_due_on is distinct from greatest(
    private.monthly_payment_due_on(v_month, 31), v_today
  ) then
    raise exception 'Initial obligation has wrong due date: %', v_due_on;
  end if;

  perform public.configure_monthly_payment_plan(v_group_id, 125.00, 1);
  if not exists (
    select 1 from public.monthly_payment_plans
    where group_id = v_group_id and stopped_at is null
      and amount = 125.00 and due_day = 1
  ) or not exists (
    select 1 from public.payment_obligations
    where group_id = v_group_id and student_id = v_student_id
      and source_type = 'monthly' and period_month = v_month
      and amount = 100.00 and due_on = v_due_on
  ) then
    raise exception 'Plan edit changed an existing obligation';
  end if;

  -- Mimic an approval after the month's selected due day. Removing this
  -- rollback-only fixture row lets the approval-specific generator reseed it.
  delete from public.payment_obligations
  where group_id = v_group_id and student_id = v_student_id
    and source_type = 'monthly' and period_month = v_month;
  v_inserted := private.generate_monthly_payment_obligations(
    v_group_id, v_student_id
  );
  if v_inserted <> 1 or not exists (
    select 1 from public.payment_obligations
    where group_id = v_group_id and student_id = v_student_id
      and source_type = 'monthly' and period_month = v_month
      and amount = 125.00 and due_on = v_today
  ) then
    raise exception 'Approval due-date mismatch: inserted %, actual %, expected %',
      v_inserted,
      (select jsonb_build_object('amount', amount, 'due_on', due_on)
       from public.payment_obligations
       where group_id = v_group_id and student_id = v_student_id
         and source_type = 'monthly' and period_month = v_month),
      v_today;
  end if;

  perform public.configure_monthly_payment_plan(v_group_id, 140.00, 31);
  perform public.configure_monthly_payment_plan(v_group_id, 150.00);
  if not exists (
    select 1 from public.monthly_payment_plans
    where group_id = v_group_id and stopped_at is null
      and amount = 150.00 and due_day = 31
  ) then
    raise exception 'Legacy two-argument RPC changed the due day';
  end if;

  if has_function_privilege('anon',
      'public.configure_monthly_payment_plan(uuid,numeric,integer)',
      'EXECUTE')
    or not has_function_privilege('authenticated',
      'public.configure_monthly_payment_plan(uuid,numeric,integer)',
      'EXECUTE') then
    raise exception 'New RPC execution grants are incorrect';
  end if;

  raise notice 'Phase 5 monthly due-day smoke test passed';
end;
$$;

rollback;
