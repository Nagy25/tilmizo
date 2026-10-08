-- Run against a project with one active group, scheduled session, and approved student.
-- Everything created or changed here rolls back.
begin;

do $$
declare
  v_group uuid;
  v_teacher uuid;
  v_student uuid;
  v_session uuid;
  v_approved_session uuid;
begin
  select g.id,g.teacher_id,m.student_id,s.id,m.approved_session_id
  into v_group,v_teacher,v_student,v_session,v_approved_session
  from public.groups g
  join public.group_memberships m on m.group_id=g.id
  join public.class_sessions s on s.group_id=g.id
  where g.is_active and not g.is_suspended and m.status='active'
    and m.approved_session_id is not null and s.status='scheduled'
  limit 1;
  if v_group is null then raise exception 'Missing Phase 6 test fixture'; end if;
  perform set_config('phase6.group',v_group::text,true);
  perform set_config('phase6.teacher',v_teacher::text,true);
  perform set_config('phase6.student',v_student::text,true);
  perform set_config('phase6.session',v_session::text,true);
  perform set_config('phase6.approved_session',v_approved_session::text,true);
end; $$;

set local role authenticated;

do $$
declare v_homework public.homework%rowtype; v_announcement public.announcements%rowtype;
begin
  perform set_config('request.jwt.claim.sub',current_setting('phase6.teacher'),true);
  perform set_config('request.jwt.claims',jsonb_build_object(
    'sub',current_setting('phase6.teacher'),'session_id',gen_random_uuid())::text,true);
  v_homework := public.create_homework(current_setting('phase6.session')::uuid,
    'Bring the written solution','link',
    (now() at time zone 'Africa/Cairo')::date);
  v_announcement := public.create_announcement(current_setting('phase6.group')::uuid,
    'Test announcement','Test body');
  perform set_config('phase6.homework',v_homework.id::text,true);
  perform set_config('phase6.announcement',v_announcement.id::text,true);
  if not exists(select 1 from public.homework where id=v_homework.id)
    or not exists(select 1 from public.announcements where id=v_announcement.id) then
    raise exception 'Teacher cannot read created content'; end if;
end; $$;

do $$
declare v_submission public.homework_link_submissions%rowtype;
begin
  perform set_config('request.jwt.claim.sub',current_setting('phase6.student'),true);
  perform set_config('request.jwt.claims',jsonb_build_object(
    'sub',current_setting('phase6.student'),
    'session_id',current_setting('phase6.approved_session'))::text,true);
  if not exists(select 1 from public.homework where id=current_setting('phase6.homework')::uuid)
    or not exists(select 1 from public.announcements where id=current_setting('phase6.announcement')::uuid) then
    raise exception 'Approved student cannot read content'; end if;
  v_submission := public.submit_homework_link(current_setting('phase6.homework')::uuid,
    'https://example.com/answer');
  if v_submission.student_id<>current_setting('phase6.student')::uuid then
    raise exception 'Submission owner mismatch'; end if;
  perform public.mark_announcement_read(current_setting('phase6.announcement')::uuid);
  if not exists(select 1 from public.announcement_reads
    where announcement_id=current_setting('phase6.announcement')::uuid) then
    raise exception 'Announcement read state missing'; end if;
  if (select count(*) from public.user_notifications
    where group_id=current_setting('phase6.group')::uuid
      and target_id in (current_setting('phase6.homework')::uuid,
        current_setting('phase6.announcement')::uuid))<>2 then
    raise exception 'Expected homework and announcement notifications'; end if;
  perform public.mark_all_notifications_read();
end; $$;

do $$
begin
  perform set_config('request.jwt.claims',jsonb_build_object(
    'sub',current_setting('phase6.student'),'session_id',gen_random_uuid())::text,true);
  if exists(select 1 from public.homework where id=current_setting('phase6.homework')::uuid)
    or exists(select 1 from public.announcements where id=current_setting('phase6.announcement')::uuid) then
    raise exception 'Replaced student session can read group content'; end if;
  begin
    perform public.submit_homework_link(current_setting('phase6.homework')::uuid,
      'https://example.com/replaced');
    raise exception 'Replaced session submitted a link';
  exception when insufficient_privilege then null;
  end;
end; $$;

do $$
begin
  perform set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
  perform set_config('request.jwt.claims',jsonb_build_object(
    'sub',current_setting('request.jwt.claim.sub'),'session_id',gen_random_uuid())::text,true);
  if exists(select 1 from public.homework where id=current_setting('phase6.homework')::uuid)
    or exists(select 1 from public.announcements
      where id=current_setting('phase6.announcement')::uuid)
    or exists(select 1 from public.user_notifications
      where target_id=current_setting('phase6.homework')::uuid) then
    raise exception 'Unrelated user can read group data'; end if;
end; $$;

do $$
begin
  perform set_config('request.jwt.claim.sub',current_setting('phase6.teacher'),true);
  perform public.delete_homework(current_setting('phase6.homework')::uuid);
  if exists(select 1 from public.homework_link_submissions
    where homework_id=current_setting('phase6.homework')::uuid) then
    raise exception 'Deleted homework kept link submissions'; end if;
end; $$;

reset role;
rollback;
