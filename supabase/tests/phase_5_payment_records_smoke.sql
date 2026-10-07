-- Run in the Supabase SQL editor. All fixture mutations roll back.
-- Requires an active group with an active student and no monthly plan.
begin;

do $$
declare
  v_group_id uuid;
  v_teacher_id uuid;
  v_student_id uuid;
  v_month date := private.current_cairo_month();
  v_obligation_id uuid;
  v_receipt_id uuid;
  v_session_id uuid;
  v_item_id uuid;
  v_count integer;
begin
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
  limit 1;
  if v_group_id is null then
    raise exception 'An active group/student fixture without a plan is required';
  end if;

  perform set_config('request.jwt.claim.sub', v_teacher_id::text, true);

  perform public.configure_monthly_payment_plan(v_group_id, 100.00);
  select count(*) into v_count from public.payment_obligations
  where group_id = v_group_id and student_id = v_student_id
    and source_type = 'monthly' and period_month = v_month
    and amount = 100.00 and status = 'unpaid';
  if v_count <> 1 then
    raise exception 'Current month obligation was not generated';
  end if;
  if private.generate_monthly_payment_obligations(v_group_id) <> 0 then
    raise exception 'Repeated monthly generation was not idempotent';
  end if;

  perform public.configure_monthly_payment_plan(v_group_id, 125.00);
  if exists (
    select 1 from public.payment_obligations
    where group_id = v_group_id and source_type = 'monthly'
      and period_month = v_month and amount <> 100.00
  ) then
    raise exception 'Plan edit changed an existing obligation';
  end if;

  perform public.create_one_time_group_payment(
    v_group_id, 'Test materials', 30.00, 'Rollback-only fixture'
  );
  select id into v_obligation_id from public.payment_obligations
  where group_id = v_group_id and student_id = v_student_id
    and source_type = 'one_time' and title = 'Test materials';
  if v_obligation_id is null then
    raise exception 'One-time student obligation was not generated';
  end if;

  select id into v_receipt_id
  from public.mark_payment_paid(v_obligation_id, 'cash');
  if not exists (
    select 1 from public.payment_receipts
    where id = v_receipt_id and amount = 30.00
      and method = 'cash' and voided_at is null
  ) then
    raise exception 'Full-amount receipt was not created';
  end if;
  perform public.void_paid_payment(v_receipt_id);
  if not exists (
    select 1 from public.payment_obligations
    where id = v_obligation_id and status = 'unpaid'
  ) or not exists (
    select 1 from public.payment_receipts
    where id = v_receipt_id and voided_at is not null
  ) then
    raise exception 'Paid-mark correction did not retain its audit trail';
  end if;

  select (response->'session'->>'id')::uuid,
    (response->'payment_item'->>'id')::uuid
  into v_session_id, v_item_id
  from (
    select public.create_manual_session_with_payment(
      v_group_id, now() + interval '2 days', now() + interval '2 days 1 hour',
      'physical', 'Test room', null, null, 40.00
    ) as response
  ) as created;
  if v_session_id is null or v_item_id is null or not exists (
    select 1 from public.payment_obligations
    where session_payment_id = v_item_id
      and student_id = v_student_id and amount = 40.00
      and status = 'unpaid'
  ) then
    raise exception 'Atomic session payment was not generated';
  end if;

  update public.class_sessions set status = 'cancelled'
  where id = v_session_id;
  if not exists (
    select 1 from public.payment_obligations
    where session_payment_id = v_item_id
      and student_id = v_student_id and status = 'void'
  ) then
    raise exception 'Cancelling the session did not void unpaid obligations';
  end if;

  select (response->'session'->>'id')::uuid,
    (response->'payment_item'->>'id')::uuid
  into v_session_id, v_item_id
  from (
    select public.create_manual_session_with_payment(
      v_group_id, now() + interval '4 days', now() + interval '4 days 1 hour',
      'physical', 'Test room', null, null, 50.00
    ) as response
  ) as created;
  select id into v_obligation_id from public.payment_obligations
  where session_payment_id = v_item_id and student_id = v_student_id;
  select id into v_receipt_id
  from public.mark_payment_paid(v_obligation_id, 'instapay');
  update public.class_sessions set status = 'cancelled'
  where id = v_session_id;
  if not exists (
    select 1 from public.payment_obligations
    where id = v_obligation_id and status = 'paid'
  ) then
    raise exception 'Cancelling a session erased paid history';
  end if;
  perform public.void_paid_payment(v_receipt_id);
  if not exists (
    select 1 from public.payment_obligations
    where id = v_obligation_id and status = 'void'
  ) then
    raise exception 'Corrected cancelled-session payment became due again';
  end if;

  perform public.set_group_suspension(v_group_id, true);
  if private.generate_monthly_payment_obligations(v_group_id) <> 0 then
    raise exception 'Suspended group received a new monthly obligation';
  end if;
  begin
    perform public.create_one_time_group_payment(v_group_id, 'Blocked', 1.00);
    raise exception 'Suspended group accepted a new obligation';
  exception when insufficient_privilege then
    null;
  end;
  begin
    perform public.create_manual_class_session(
      v_group_id, now() + interval '3 days', now() + interval '3 days 1 hour',
      'physical', 'Test room'
    );
    raise exception 'Suspended group accepted a new session';
  exception when insufficient_privilege then
    null;
  end;
  perform public.set_group_suspension(v_group_id, false);
  perform public.stop_monthly_payment_plan(v_group_id);

  raise notice 'Phase 5 payment lifecycle smoke test passed';
end;
$$;

rollback;
