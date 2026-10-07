-- Run in the Supabase SQL editor. All fixture mutations roll back.
begin;

do $$
declare
  v_group_id uuid;
  v_teacher_id uuid;
  v_student_id uuid;
  v_obligation_id uuid;
begin
  select owned_group.id, owned_group.teacher_id, membership.student_id
  into v_group_id, v_teacher_id, v_student_id
  from public.groups as owned_group
  join public.group_memberships as membership
    on membership.group_id = owned_group.id
  where owned_group.is_active and not owned_group.is_suspended
    and membership.status = 'active'
  limit 1;
  if v_group_id is null then
    raise exception 'An active group/student fixture is required';
  end if;

  perform set_config('request.jwt.claim.sub', v_teacher_id::text, true);
  perform public.create_one_time_group_payment(
    v_group_id, 'RLS rollback fixture', 1.00
  );
  select id into v_obligation_id from public.payment_obligations
  where group_id = v_group_id and student_id = v_student_id
    and title = 'RLS rollback fixture';
  perform public.mark_payment_paid(v_obligation_id, 'cash');

  perform set_config('phase5.test_group_id', v_group_id::text, true);
  perform set_config('phase5.test_teacher_id', v_teacher_id::text, true);
  perform set_config('phase5.test_student_id', v_student_id::text, true);
  perform set_config('phase5.test_obligation_id', v_obligation_id::text, true);
end;
$$;

set local role authenticated;

do $$
declare
  v_group_id uuid := current_setting('phase5.test_group_id')::uuid;
  v_teacher_id uuid := current_setting('phase5.test_teacher_id')::uuid;
  v_student_id uuid := current_setting('phase5.test_student_id')::uuid;
  v_obligation_id uuid := current_setting('phase5.test_obligation_id')::uuid;
begin
  if has_table_privilege('authenticated', 'public.payment_obligations', 'INSERT')
    or has_table_privilege('authenticated', 'public.payment_receipts', 'UPDATE')
    or has_table_privilege('anon', 'public.payment_obligations', 'SELECT') then
    raise exception 'Financial table grants are too broad';
  end if;

  perform set_config('request.jwt.claim.sub', v_student_id::text, true);
  if not exists (
    select 1 from public.payment_obligations where id = v_obligation_id
  ) or not exists (
    select 1 from public.payment_receipts
    where obligation_id = v_obligation_id
  ) then
    raise exception 'Student cannot read their own payment history';
  end if;
  if exists (
    select 1 from public.one_time_payment_items
    where group_id = v_group_id and title = 'RLS rollback fixture'
  ) then
    raise exception 'Student can read teacher-only payment settings';
  end if;

  perform set_config('request.jwt.claim.sub', gen_random_uuid()::text, true);
  if exists (
    select 1 from public.payment_obligations where id = v_obligation_id
  ) or exists (
    select 1 from public.payment_receipts
    where obligation_id = v_obligation_id
  ) then
    raise exception 'Unrelated user can read payment history';
  end if;

  perform set_config('request.jwt.claim.sub', v_teacher_id::text, true);
  if not exists (
    select 1 from public.payment_obligations where id = v_obligation_id
  ) or not exists (
    select 1 from public.payment_receipts
    where obligation_id = v_obligation_id
  ) or not exists (
    select 1 from public.one_time_payment_items
    where group_id = v_group_id and title = 'RLS rollback fixture'
  ) then
    raise exception 'Group owner cannot read payment history and settings';
  end if;

  raise notice 'Phase 5 RLS smoke test passed';
end;
$$;

rollback;
