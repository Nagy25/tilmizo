begin;

create table public.homework (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null,
  session_id uuid not null,
  teacher_id uuid not null,
  instructions text check (instructions is null or char_length(instructions) <= 10000),
  submission_type text not null check (submission_type in ('manual', 'link', 'none')),
  due_date date,
  created_at timestamptz not null default now(),
  constraint homework_session_group_fk foreign key (session_id, group_id)
    references public.class_sessions(id, group_id) on delete restrict,
  constraint homework_group_teacher_fk foreign key (group_id, teacher_id)
    references public.groups(id, teacher_id) on delete restrict,
  unique (id, group_id)
);
create index homework_group_created_idx on public.homework(group_id, created_at desc);
create index homework_session_created_idx on public.homework(session_id, created_at desc);
create index homework_due_idx on public.homework(due_date) where due_date is not null;

create table public.homework_resources (
  homework_id uuid not null,
  group_id uuid not null,
  resource_id uuid not null references public.resources(id) on delete restrict,
  primary key (homework_id, resource_id),
  foreign key (homework_id, group_id) references public.homework(id, group_id) on delete cascade
);
create index homework_resources_resource_idx on public.homework_resources(resource_id);

create table public.homework_link_submissions (
  homework_id uuid not null references public.homework(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete restrict,
  url text not null check (url ~* '^https://[^[:space:]]+$' and char_length(url) <= 2048),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (homework_id, student_id)
);
create index homework_submissions_student_idx on public.homework_link_submissions(student_id, updated_at desc);
create trigger set_homework_submissions_updated_at before update on public.homework_link_submissions
  for each row execute function private.set_updated_at();

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null,
  teacher_id uuid not null,
  title text not null check (btrim(title) <> '' and char_length(title) <= 200),
  body text not null check (btrim(body) <> '' and char_length(body) <= 10000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (group_id, teacher_id) references public.groups(id, teacher_id) on delete restrict
);
create index announcements_group_created_idx on public.announcements(group_id, created_at desc);
create trigger set_announcements_updated_at before update on public.announcements
  for each row execute function private.set_updated_at();

create table public.announcement_reads (
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete restrict,
  read_at timestamptz not null default now(),
  primary key (announcement_id, student_id)
);
create index announcement_reads_student_idx on public.announcement_reads(student_id, read_at desc);

create table public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  group_id uuid references public.groups(id) on delete set null,
  event_type text not null check (event_type in (
    'announcement_new','homework_new','homework_due_soon','resource_new',
    'session_rescheduled','session_cancelled','session_upcoming',
    'payment_charge_new','payment_recorded','payment_overdue'
  )),
  target_id uuid,
  title text not null,
  body text,
  dedupe_key text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  unique (user_id, dedupe_key)
);
create index user_notifications_user_created_idx on public.user_notifications(user_id, created_at desc);
create index user_notifications_user_unread_idx on public.user_notifications(user_id, created_at desc) where read_at is null;

create table private.notification_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid not null,
  token text not null unique check (btrim(token) <> '' and char_length(token) <= 4096),
  platform text not null check (platform in ('android','ios')),
  app text not null check (app in ('student','teacher')),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index notification_devices_user_idx on private.notification_devices(user_id);

create table private.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.user_notifications(id) on delete cascade,
  device_id uuid not null references private.notification_devices(id) on delete cascade,
  state text not null default 'pending' check (state in ('pending','processing','sent','failed')),
  attempts integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  claimed_at timestamptz,
  sent_at timestamptz,
  last_error text,
  unique (notification_id, device_id)
);
create index notification_deliveries_pending_idx on private.notification_deliveries(next_attempt_at)
  where state in ('pending','processing');

alter table public.homework enable row level security;
alter table public.homework_resources enable row level security;
alter table public.homework_link_submissions enable row level security;
alter table public.announcements enable row level security;
alter table public.announcement_reads enable row level security;
alter table public.user_notifications enable row level security;
alter table private.notification_devices enable row level security;
alter table private.notification_deliveries enable row level security;

revoke all on public.homework, public.homework_resources, public.homework_link_submissions,
  public.announcements, public.announcement_reads, public.user_notifications from public, anon, authenticated;
grant select on public.homework, public.homework_resources, public.homework_link_submissions,
  public.announcements, public.announcement_reads, public.user_notifications to authenticated;
grant all on public.homework, public.homework_resources, public.homework_link_submissions,
  public.announcements, public.announcement_reads, public.user_notifications to service_role;
revoke all on private.notification_devices, private.notification_deliveries from public, anon, authenticated;
grant all on private.notification_devices, private.notification_deliveries to service_role;

create policy homework_read on public.homework for select to authenticated using (
  private.owns_group(group_id) or private.has_approved_group_session(group_id));
create policy homework_resources_read on public.homework_resources for select to authenticated using (
  private.owns_group(group_id) or private.has_approved_group_session(group_id));
create policy homework_submissions_read on public.homework_link_submissions for select to authenticated using (
  exists (select 1 from public.homework h where h.id = homework_id and (
    private.owns_group(h.group_id) or
    (student_id = (select auth.uid()) and private.has_approved_group_session(h.group_id)))));
create policy announcements_read on public.announcements for select to authenticated using (
  private.owns_group(group_id) or private.has_approved_group_session(group_id));
create policy announcement_reads_read on public.announcement_reads for select to authenticated using (
  exists (select 1 from public.announcements a where a.id = announcement_id and (
    private.owns_group(a.group_id) or
    (student_id = (select auth.uid()) and private.has_approved_group_session(a.group_id)))));
create policy notifications_read on public.user_notifications for select to authenticated using (
  user_id = (select auth.uid()));

create function private.assert_phase6_writable_group(p_group_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_teacher uuid;
begin
  select teacher_id into v_teacher from public.groups
  where id = p_group_id and teacher_id = (select auth.uid())
    and is_active and not is_suspended for update;
  if v_teacher is null then raise exception 'Group is not writable' using errcode = '42501'; end if;
  return v_teacher;
end; $$;

create function private.notify_group_students(
  p_group_id uuid, p_event_type text, p_target_id uuid, p_title text, p_body text,
  p_event_key text
) returns void language sql security definer set search_path = '' as $$
  insert into public.user_notifications(user_id, group_id, event_type, target_id, title, body, dedupe_key)
  select m.student_id, p_group_id, p_event_type, p_target_id, p_title, p_body, p_event_key
  from public.group_memberships m
  where m.group_id = p_group_id and m.status = 'active'
    and m.approved_session_id is not null
  on conflict (user_id, dedupe_key) do nothing;
$$;

create function private.enqueue_notification_deliveries() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into private.notification_deliveries(notification_id, device_id)
  select new.id, d.id from private.notification_devices d
  where d.user_id = new.user_id and (
    d.app = 'teacher' or exists (
      select 1 from public.group_memberships m
      where m.group_id=new.group_id and m.student_id=d.user_id
        and m.status='active' and m.approved_session_id=d.session_id))
  on conflict do nothing;
  return new;
end; $$;
create trigger enqueue_notification_deliveries after insert on public.user_notifications
  for each row execute function private.enqueue_notification_deliveries();

create function public.create_homework(
  p_session_id uuid, p_instructions text, p_submission_type text,
  p_due_date date default null, p_resource_ids uuid[] default '{}'::uuid[]
) returns public.homework language plpgsql security definer set search_path = '' as $$
declare v_session public.class_sessions%rowtype; v_homework public.homework%rowtype;
  v_count integer; v_expected integer;
begin
  select * into v_session from public.class_sessions where id = p_session_id;
  if not found or v_session.status = 'cancelled' then
    raise exception 'An uncancelled session is required' using errcode = '22023'; end if;
  perform private.assert_phase6_writable_group(v_session.group_id);
  if p_submission_type not in ('manual','link','none') or p_submission_type is null then
    raise exception 'Invalid submission type' using errcode = '22023'; end if;
  if p_instructions is not null and char_length(p_instructions) > 10000 then
    raise exception 'Instructions too long' using errcode = '22023'; end if;
  if array_position(coalesce(p_resource_ids,'{}'::uuid[]),null) is not null then
    raise exception 'Invalid resource list' using errcode = '22023'; end if;
  select count(distinct x) into v_expected from unnest(coalesce(p_resource_ids,'{}'::uuid[])) x;
  select count(*) into v_count from public.resources r
    where r.id = any(coalesce(p_resource_ids,'{}'::uuid[]))
      and r.group_id = v_session.group_id and r.storage_path is not null
      and (r.session_id is null or r.session_id = p_session_id);
  if v_count <> v_expected or (nullif(btrim(coalesce(p_instructions,'')),'') is null and v_count = 0) then
    raise exception 'Instructions or valid file resources are required' using errcode = '22023'; end if;
  insert into public.homework(group_id,session_id,teacher_id,instructions,submission_type,due_date)
  values (v_session.group_id,p_session_id,(select auth.uid()),nullif(btrim(p_instructions),''),p_submission_type,p_due_date)
  returning * into v_homework;
  insert into public.homework_resources(homework_id,group_id,resource_id)
    select v_homework.id,v_session.group_id,distinct_ids.id
    from (select distinct unnest(coalesce(p_resource_ids,'{}'::uuid[])) id) distinct_ids;
  return v_homework;
end; $$;

create function public.delete_homework(p_homework_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare v_group_id uuid;
begin
  select group_id into v_group_id from public.homework where id = p_homework_id;
  if v_group_id is null then raise exception 'Homework not found' using errcode = 'P0002'; end if;
  perform private.assert_phase6_writable_group(v_group_id);
  delete from public.homework where id = p_homework_id;
end; $$;

create function public.submit_homework_link(p_homework_id uuid, p_url text)
returns public.homework_link_submissions language plpgsql security definer set search_path = '' as $$
declare v_homework public.homework%rowtype; v_submission public.homework_link_submissions%rowtype;
begin
  select * into v_homework from public.homework where id = p_homework_id;
  if not found or v_homework.submission_type <> 'link' or
     not private.has_approved_group_session(v_homework.group_id) or
     (v_homework.due_date is not null and (now() at time zone 'Africa/Cairo')::date > v_homework.due_date) then
    raise exception 'Link submission is not allowed' using errcode = '42501'; end if;
  if p_url is null or p_url !~* '^https://[^[:space:]]+$' or char_length(p_url) > 2048 then
    raise exception 'A valid HTTPS link is required' using errcode = '22023'; end if;
  insert into public.homework_link_submissions(homework_id,student_id,url)
  values (p_homework_id,(select auth.uid()),p_url)
  on conflict (homework_id,student_id) do update set url = excluded.url
  returning * into v_submission;
  return v_submission;
end; $$;

create function public.create_announcement(p_group_id uuid,p_title text,p_body text)
returns public.announcements language plpgsql security definer set search_path = '' as $$
declare v_row public.announcements%rowtype;
begin
  perform private.assert_phase6_writable_group(p_group_id);
  insert into public.announcements(group_id,teacher_id,title,body)
  values(p_group_id,(select auth.uid()),p_title,p_body) returning * into v_row;
  return v_row;
end; $$;
create function public.update_announcement(p_announcement_id uuid,p_title text,p_body text)
returns public.announcements language plpgsql security definer set search_path = '' as $$
declare v_group uuid; v_row public.announcements%rowtype;
begin
  select group_id into v_group from public.announcements where id = p_announcement_id;
  if v_group is null then raise exception 'Announcement not found' using errcode = 'P0002'; end if;
  perform private.assert_phase6_writable_group(v_group);
  update public.announcements set title=p_title,body=p_body where id=p_announcement_id returning * into v_row;
  return v_row;
end; $$;
create function public.delete_announcement(p_announcement_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare v_group uuid;
begin
  select group_id into v_group from public.announcements where id=p_announcement_id;
  if v_group is null then raise exception 'Announcement not found' using errcode = 'P0002'; end if;
  perform private.assert_phase6_writable_group(v_group);
  delete from public.announcements where id=p_announcement_id;
end; $$;
create function public.mark_announcement_read(p_announcement_id uuid) returns timestamptz
language plpgsql security definer set search_path = '' as $$
declare v_group uuid; v_read_at timestamptz;
begin
  select group_id into v_group from public.announcements where id=p_announcement_id;
  if v_group is null or not private.has_approved_group_session(v_group) then
    raise exception 'Announcement not accessible' using errcode='42501'; end if;
  insert into public.announcement_reads(announcement_id,student_id)
  values(p_announcement_id,(select auth.uid()))
  on conflict (announcement_id,student_id) do update set read_at=excluded.read_at
  returning read_at into v_read_at;
  return v_read_at;
end; $$;
create function public.mark_notification_read(p_notification_id uuid) returns timestamptz
language plpgsql security definer set search_path = '' as $$
declare v_read_at timestamptz;
begin
  update public.user_notifications set read_at=coalesce(read_at,now())
  where id=p_notification_id and user_id=(select auth.uid()) returning read_at into v_read_at;
  if v_read_at is null then raise exception 'Notification not found' using errcode='P0002'; end if;
  return v_read_at;
end; $$;
create function public.mark_all_notifications_read() returns integer
language plpgsql security definer set search_path = '' as $$
declare v_count integer;
begin
  if (select auth.uid()) is null or nullif((select auth.jwt())->>'session_id','') is null then
    raise exception 'Authentication required' using errcode='42501'; end if;
  update public.user_notifications set read_at=now()
  where user_id=(select auth.uid()) and read_at is null;
  get diagnostics v_count = row_count;
  return v_count;
end; $$;
create function public.register_notification_device(p_token text,p_platform text,p_app text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if (select auth.uid()) is null or nullif((select auth.jwt())->>'session_id','') is null then
    raise exception 'Authentication required' using errcode='42501'; end if;
  if p_token is null or btrim(p_token)='' or char_length(p_token)>4096
    or p_platform not in ('android','ios') or p_app not in ('student','teacher') then
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
create function public.revoke_notification_device(p_token text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  delete from private.notification_devices where token=p_token and user_id=(select auth.uid());
end; $$;

create function private.phase6_content_notifications() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_table_name='homework' then
    perform private.notify_group_students(new.group_id,'homework_new',new.id,'واجب جديد',null,'homework:'||new.id);
  elsif tg_table_name='announcements' then
    perform private.notify_group_students(new.group_id,'announcement_new',new.id,new.title,null,'announcement:'||new.id);
  elsif tg_table_name='resources' then
    perform private.notify_group_students(new.group_id,'resource_new',new.id,new.title,null,'resource:'||new.id);
  end if;
  return new;
end; $$;
create trigger phase6_homework_new after insert on public.homework
  for each row execute function private.phase6_content_notifications();
create trigger phase6_announcement_new after insert on public.announcements
  for each row execute function private.phase6_content_notifications();
create trigger phase6_resource_new after insert on public.resources
  for each row execute function private.phase6_content_notifications();

create function private.phase6_session_notifications() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.status='cancelled' and old.status is distinct from 'cancelled' then
    perform private.notify_group_students(new.group_id,'session_cancelled',new.id,
      'تم إلغاء الحصة',null,'session-cancelled:'||new.id);
  elsif new.status='scheduled' and (new.starts_at is distinct from old.starts_at
    or new.ends_at is distinct from old.ends_at) then
    perform private.notify_group_students(new.group_id,'session_rescheduled',new.id,
      'تم تغيير موعد الحصة',null,'session-rescheduled:'||new.id||':'||new.updated_at);
  end if;
  return new;
end; $$;
create trigger phase6_session_changed after update on public.class_sessions
  for each row execute function private.phase6_session_notifications();

create function private.phase6_payment_notifications() returns trigger
language plpgsql security definer set search_path = '' as $$
declare v_obligation public.payment_obligations%rowtype;
begin
  if tg_table_name='payment_obligations' then
    insert into public.user_notifications(user_id,group_id,event_type,target_id,title,body,dedupe_key)
    values(new.student_id,new.group_id,'payment_charge_new',new.id,'مبلغ جديد مستحق',new.title,
      'payment-charge:'||new.id) on conflict (user_id,dedupe_key) do nothing;
  elsif tg_table_name='payment_receipts' and new.voided_at is null then
    select * into v_obligation from public.payment_obligations where id=new.obligation_id;
    insert into public.user_notifications(user_id,group_id,event_type,target_id,title,body,dedupe_key)
    values(v_obligation.student_id,v_obligation.group_id,'payment_recorded',v_obligation.id,
      'تم تسجيل الدفع',v_obligation.title,'payment-recorded:'||new.id)
    on conflict (user_id,dedupe_key) do nothing;
  end if;
  return new;
end; $$;
create trigger phase6_payment_charge after insert on public.payment_obligations
  for each row execute function private.phase6_payment_notifications();
create trigger phase6_payment_recorded after insert on public.payment_receipts
  for each row execute function private.phase6_payment_notifications();

create function private.generate_phase6_reminders() returns integer
language plpgsql security definer set search_path = '' as $$
declare v_today date := (now() at time zone 'Africa/Cairo')::date;
  v_count integer := 0; v_rows integer;
begin
  insert into public.user_notifications(user_id,group_id,event_type,target_id,title,dedupe_key)
  select m.student_id,h.group_id,'homework_due_soon',h.id,'اقترب موعد تسليم الواجب',
    'homework-due:'||h.id||':'||h.due_date
  from public.homework h join public.groups g on g.id=h.group_id
  join public.group_memberships m on m.group_id=h.group_id
  where g.is_active and h.due_date is not null and h.due_date between v_today and v_today+1
    and now() >= ((h.due_date-1) + time '09:00') at time zone 'Africa/Cairo'
    and m.status='active' and m.approved_session_id is not null
  on conflict (user_id,dedupe_key) do nothing;
  get diagnostics v_rows=row_count; v_count:=v_count+v_rows;

  insert into public.user_notifications(user_id,group_id,event_type,target_id,title,dedupe_key)
  select m.student_id,s.group_id,'session_upcoming',s.id,'الحصة تبدأ قريبًا',
    'session-upcoming:'||s.id||':'||s.starts_at
  from public.class_sessions s join public.groups g on g.id=s.group_id
  join public.group_memberships m on m.group_id=s.group_id
  where g.is_active and s.status='scheduled'
    and s.starts_at > now() and s.starts_at <= now()+interval '2 hours'
    and m.status='active' and m.approved_session_id is not null
  on conflict (user_id,dedupe_key) do nothing;
  get diagnostics v_rows=row_count; v_count:=v_count+v_rows;

  insert into public.user_notifications(user_id,group_id,event_type,target_id,title,body,dedupe_key)
  select o.student_id,o.group_id,'payment_overdue',o.id,'تأخر موعد الدفع',o.title,
    'payment-overdue:'||o.id
  from public.payment_obligations o join public.groups g on g.id=o.group_id
  join public.group_memberships m on m.group_id=o.group_id and m.student_id=o.student_id
  where g.is_active and o.status='unpaid' and o.due_on < v_today
    and now() >= ((o.due_on+1) + time '09:00') at time zone 'Africa/Cairo'
    and m.status='active' and m.approved_session_id is not null
  on conflict (user_id,dedupe_key) do nothing;
  get diagnostics v_rows=row_count; v_count:=v_count+v_rows;
  return v_count;
end; $$;

create function public.phase6_claim_deliveries(p_limit integer default 100)
returns table(id uuid, token text, title text, body text, event_type text, target_id uuid, attempts integer)
language plpgsql security definer set search_path = '' as $$
begin
  update private.notification_deliveries d set state='failed',last_error='session_replaced'
  from private.notification_devices dev, public.user_notifications n
  where d.device_id=dev.id and d.notification_id=n.id and dev.app='student'
    and d.state in ('pending','processing') and not exists (
      select 1 from public.group_memberships m where m.group_id=n.group_id
      and m.student_id=dev.user_id and m.status='active'
      and m.approved_session_id=dev.session_id);
  return query
  with picked as (
    select d.id from private.notification_deliveries d
    where (d.state='pending' and d.next_attempt_at<=now())
       or (d.state='processing' and d.claimed_at<now()-interval '10 minutes')
    order by d.next_attempt_at limit least(greatest(p_limit,1),100) for update skip locked
  ), updated as (
    update private.notification_deliveries d set state='processing',claimed_at=now(),attempts=d.attempts+1
    from picked where d.id=picked.id returning d.*
  )
  select u.id,dev.token,n.title,coalesce(n.body,''),n.event_type,n.target_id,u.attempts
  from updated u join private.notification_devices dev on dev.id=u.device_id
  join public.user_notifications n on n.id=u.notification_id
  where dev.app='teacher' or exists (
    select 1 from public.group_memberships m where m.group_id=n.group_id
      and m.student_id=dev.user_id and m.status='active'
      and m.approved_session_id=dev.session_id);
end; $$;
create function public.phase6_finish_delivery(p_id uuid,p_result text,p_error text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_result not in ('sent','retry','invalid','failed') then raise exception 'Invalid result'; end if;
  if p_result='invalid' then
    delete from private.notification_devices dev using private.notification_deliveries d
      where d.id=p_id and dev.id=d.device_id;
  else
    update private.notification_deliveries set
      state=case when p_result='sent' then 'sent' when p_result='retry' and attempts<8 then 'pending' else 'failed' end,
      sent_at=case when p_result='sent' then now() else sent_at end,
      next_attempt_at=case when p_result='retry' then now()+make_interval(mins=>least(240,2^least(attempts,7))::integer) else next_attempt_at end,
      last_error=left(p_error,300)
    where id=p_id;
  end if;
end; $$;

revoke all on function private.assert_phase6_writable_group(uuid),
  private.notify_group_students(uuid,text,uuid,text,text,text),
  private.enqueue_notification_deliveries(), private.phase6_content_notifications(),
  private.phase6_session_notifications(), private.phase6_payment_notifications(),
  private.generate_phase6_reminders() from public,anon,authenticated;
revoke all on function public.create_homework(uuid,text,text,date,uuid[]),public.delete_homework(uuid),
  public.submit_homework_link(uuid,text),public.create_announcement(uuid,text,text),
  public.update_announcement(uuid,text,text),public.delete_announcement(uuid),
  public.mark_announcement_read(uuid),public.mark_notification_read(uuid),
  public.mark_all_notifications_read(),public.register_notification_device(text,text,text),
  public.revoke_notification_device(text),public.phase6_claim_deliveries(integer),
  public.phase6_finish_delivery(uuid,text,text) from public,anon,authenticated;
grant execute on function public.create_homework(uuid,text,text,date,uuid[]),public.delete_homework(uuid),
  public.submit_homework_link(uuid,text),public.create_announcement(uuid,text,text),
  public.update_announcement(uuid,text,text),public.delete_announcement(uuid),
  public.mark_announcement_read(uuid),public.mark_notification_read(uuid),
  public.mark_all_notifications_read(),public.register_notification_device(text,text,text),
  public.revoke_notification_device(text) to authenticated;
grant execute on function public.phase6_claim_deliveries(integer),
  public.phase6_finish_delivery(uuid,text,text) to service_role;

select cron.schedule('phase6-reminders','*/15 * * * *',
  'select private.generate_phase6_reminders()');

select cron.schedule('phase6-push-dispatch','*/5 * * * *', $cron$
  with config as (
    select max(decrypted_secret) filter (where name='telmizo_project_url') as project_url,
           max(decrypted_secret) filter (where name='resource_cleanup_secret') as dispatch_secret
    from vault.decrypted_secrets
  )
  select net.http_post(
    url:=config.project_url||'/functions/v1/notification-dispatch',
    headers:=jsonb_build_object('Content-Type','application/json',
      'x-dispatch-secret',config.dispatch_secret),
    body:='{}'::jsonb
  ) from config where project_url is not null and dispatch_secret is not null;
$cron$);

commit;
