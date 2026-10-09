-- Wake the existing FCM worker as soon as a transaction creates deliverable
-- notifications. pg_net starts the HTTP request only after commit, so the
-- worker can see the committed delivery rows. The five-minute Cron job stays
-- in place for retries and failed wake-ups.
create function private.wake_pending_notification_dispatch()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_project_url text;
  v_dispatch_secret text;
begin
  -- The row trigger has already queued deliveries. A statement trigger sends
  -- one wake-up for the whole insert, not one HTTP request per student.
  if not exists (
    select 1
    from inserted_notifications n
    join private.notification_deliveries d on d.notification_id = n.id
    where d.state = 'pending'
  ) then
    return null;
  end if;

  select max(decrypted_secret) filter (where name = 'telmizo_project_url'),
         max(decrypted_secret) filter (where name = 'resource_cleanup_secret')
  into v_project_url, v_dispatch_secret
  from vault.decrypted_secrets
  where name in ('telmizo_project_url', 'resource_cleanup_secret');

  if nullif(btrim(v_project_url), '') is null
     or nullif(btrim(v_dispatch_secret), '') is null then
    return null;
  end if;

  perform net.http_post(
    url := rtrim(v_project_url, '/') || '/functions/v1/notification-dispatch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-dispatch-secret', v_dispatch_secret
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
  return null;
exception when others then
  -- A broken wake-up must never roll back the announcement, homework, or
  -- payment that created the notification. Cron will retry pending rows.
  raise warning 'Immediate notification dispatch wake-up failed (SQLSTATE %); scheduled dispatch remains available', sqlstate;
  return null;
end;
$$;

revoke all on function private.wake_pending_notification_dispatch()
from public, anon, authenticated;

create trigger wake_pending_notification_dispatch
after insert on public.user_notifications
referencing new table as inserted_notifications
for each statement
execute function private.wake_pending_notification_dispatch();
