-- Fixture-based Phase 6 lifecycle and queue test. All changes roll back.
begin;

do $$
declare v_group uuid; v_teacher uuid; v_student uuid; v_session uuid; v_auth_session uuid;
begin
  select g.id,g.teacher_id,m.student_id,s.id,m.approved_session_id
  into v_group,v_teacher,v_student,v_session,v_auth_session
  from public.groups g join public.group_memberships m on m.group_id=g.id
  join public.class_sessions s on s.group_id=g.id
  where g.is_active and not g.is_suspended and m.status='active'
    and m.approved_session_id is not null and s.status='scheduled' limit 1;
  if v_group is null then raise exception 'Missing Phase 6 fixture'; end if;
  perform set_config('phase6.group',v_group::text,true);
  perform set_config('phase6.teacher',v_teacher::text,true);
  perform set_config('phase6.student',v_student::text,true);
  perform set_config('phase6.session',v_session::text,true);
  perform set_config('phase6.auth_session',v_auth_session::text,true);
end; $$;

set local role authenticated;
do $$
declare v_homework public.homework%rowtype;
begin
  perform set_config('request.jwt.claim.sub',current_setting('phase6.teacher'),true);
  perform set_config('request.jwt.claims',jsonb_build_object(
    'sub',current_setting('phase6.teacher'),'session_id',gen_random_uuid())::text,true);
  v_homework:=public.create_homework(current_setting('phase6.session')::uuid,
    'Past deadline test','link',(now() at time zone 'Africa/Cairo')::date-1);
  perform set_config('phase6.homework',v_homework.id::text,true);
end; $$;

do $$
begin
  perform set_config('request.jwt.claim.sub',current_setting('phase6.student'),true);
  perform set_config('request.jwt.claims',jsonb_build_object(
    'sub',current_setting('phase6.student'),
    'session_id',current_setting('phase6.auth_session'))::text,true);
  begin
    perform public.submit_homework_link(current_setting('phase6.homework')::uuid,
      'https://example.com/too-late');
    raise exception 'Past-due submission was accepted';
  exception when insufficient_privilege then null;
  end;
end; $$;

reset role;
update public.groups set is_suspended=true where id=current_setting('phase6.group')::uuid;
set local role authenticated;
do $$
begin
  perform set_config('request.jwt.claim.sub',current_setting('phase6.teacher'),true);
  begin
    perform public.create_announcement(current_setting('phase6.group')::uuid,
      'Blocked','Suspended group');
    raise exception 'Suspended announcement was accepted';
  exception when insufficient_privilege then null;
  end;
end; $$;

reset role;
update public.groups set is_suspended=false,is_active=false
  where id=current_setting('phase6.group')::uuid;
set local role authenticated;
do $$
begin
  perform set_config('request.jwt.claim.sub',current_setting('phase6.teacher'),true);
  if not exists(select 1 from public.homework
    where id=current_setting('phase6.homework')::uuid) then
    raise exception 'Archived owner cannot read historical homework'; end if;
  begin
    perform public.delete_homework(current_setting('phase6.homework')::uuid);
    raise exception 'Archived homework was deleted';
  exception when insufficient_privilege then null;
  end;
end; $$;

reset role;
update public.groups set is_active=true where id=current_setting('phase6.group')::uuid;
do $$
declare v_due_homework uuid;
begin
  insert into public.homework(group_id,session_id,teacher_id,instructions,submission_type,due_date)
  values(current_setting('phase6.group')::uuid,current_setting('phase6.session')::uuid,
    current_setting('phase6.teacher')::uuid,'Cancelled session reminder','none',
    (now() at time zone 'Africa/Cairo')::date+1) returning id into v_due_homework;
  update public.class_sessions set status='cancelled'
  where id=current_setting('phase6.session')::uuid;
  perform private.generate_phase6_reminders();
  if exists(select 1 from public.user_notifications
    where target_id=v_due_homework and event_type='homework_due_soon') then
    raise exception 'Cancelled-session homework reminder was generated'; end if;
end; $$;

do $$
declare v_device uuid; v_notification uuid; v_claimed record;
begin
  insert into private.notification_devices(user_id,session_id,token,platform,app)
  values(current_setting('phase6.student')::uuid,
    current_setting('phase6.auth_session')::uuid,
    'phase6-test-token-'||gen_random_uuid(),'android','student')
  returning id into v_device;
  insert into public.user_notifications(user_id,group_id,event_type,target_id,title,dedupe_key)
  values(current_setting('phase6.student')::uuid,current_setting('phase6.group')::uuid,
    'homework_new',current_setting('phase6.homework')::uuid,'Test queue',
    'test-queue:'||gen_random_uuid()) returning id into v_notification;
  select * into v_claimed from public.phase6_claim_deliveries(100)
    where token=(select token from private.notification_devices where id=v_device);
  if v_claimed.id is null then raise exception 'Delivery was not queued'; end if;
  perform public.phase6_finish_delivery(v_claimed.id,'sent');
  if not exists(select 1 from private.notification_deliveries
    where id=v_claimed.id and state='sent') then
    raise exception 'Delivery completion failed'; end if;
end; $$;

rollback;
