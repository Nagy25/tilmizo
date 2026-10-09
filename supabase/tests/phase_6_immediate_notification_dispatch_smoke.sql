-- Run in the SQL editor with one approved student who has a registered device.
-- The transaction rolls back, so neither the notification nor its pg_net
-- request is committed or sent to the device.
begin;

do $$
declare
  v_user_id uuid;
  v_group_id uuid;
  v_notification_id uuid;
  v_request_before bigint;
begin
  select d.user_id, m.group_id
  into v_user_id, v_group_id
  from private.notification_devices d
  join public.group_memberships m on m.student_id = d.user_id
    and m.status = 'active' and m.approved_session_id = d.session_id
  where d.app = 'student'
  limit 1;
  if v_user_id is null then
    raise exception 'Missing approved student with a registered device';
  end if;

  select coalesce(max(id), 0) into v_request_before
  from net.http_request_queue;

  insert into public.user_notifications(
    user_id, group_id, event_type, title, dedupe_key
  ) values (
    v_user_id, v_group_id, 'announcement_new',
    'Rolled-back dispatch test', 'dispatch-test:' || gen_random_uuid()
  ) returning id into v_notification_id;

  if not exists (
    select 1 from private.notification_deliveries
    where notification_id = v_notification_id and state = 'pending'
  ) then
    raise exception 'Notification did not create a queued delivery';
  end if;

  if not exists (
    select 1 from net.http_request_queue
    where id > v_request_before
      and url like '%/functions/v1/notification-dispatch'
  ) then
    raise exception 'Notification did not wake the push worker';
  end if;
end;
$$;

rollback;
