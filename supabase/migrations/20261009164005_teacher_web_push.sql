-- Teacher browser FCM tokens use the same session-scoped delivery queue as
-- native devices. Keep student web registrations disabled until supported.
alter table private.notification_devices
  drop constraint notification_devices_platform_check;
alter table private.notification_devices
  add constraint notification_devices_platform_check
  check (platform in ('android', 'ios', 'web'));
alter table private.notification_devices
  add constraint notification_devices_web_teacher_check
  check (platform <> 'web' or app = 'teacher');

create or replace function public.register_notification_device(
  p_token text,
  p_platform text,
  p_app text
) returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if (select auth.uid()) is null or nullif((select auth.jwt())->>'session_id','') is null then
    raise exception 'Authentication required' using errcode='42501'; end if;
  if p_token is null or btrim(p_token)='' or char_length(p_token)>4096
    or p_platform is null or p_platform not in ('android','ios','web')
    or p_app is null or p_app not in ('student','teacher')
    or (p_platform='web' and p_app<>'teacher') then
    raise exception 'Invalid device' using errcode='22023'; end if;
  if (p_app='teacher' and not exists(select 1 from public.groups where teacher_id=(select auth.uid())))
    or (p_app='student' and not exists(select 1 from public.group_memberships where student_id=(select auth.uid()))) then
    raise exception 'Wrong app for account' using errcode='42501'; end if;
  if exists(select 1 from private.notification_devices where token=p_token and user_id<>(select auth.uid())) then
    raise exception 'Device token belongs to another account' using errcode='42501'; end if;
  insert into private.notification_devices(user_id,session_id,token,platform,app)
  values((select auth.uid()),((select auth.jwt())->>'session_id')::uuid,p_token,p_platform,p_app)
  on conflict (token) do update set platform=excluded.platform,
    app=excluded.app,session_id=excluded.session_id,last_seen_at=now()
    where notification_devices.user_id=excluded.user_id
  returning id into v_id;
  if v_id is null then raise exception 'Device token belongs to another account' using errcode='42501'; end if;
  return v_id;
end; $$;
