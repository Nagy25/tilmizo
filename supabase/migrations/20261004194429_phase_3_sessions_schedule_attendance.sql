begin;

-- Phase 1/2 were applied to this project before versioned migrations were
-- introduced. Keep their existing objects and migration history intact.
do $$
begin
  if to_regclass('public.groups') is null
    or to_regclass('public.group_memberships') is null
    or to_regclass('public.profiles') is null then
    raise exception 'Phase 3 requires the Phase 1/2 schema';
  end if;
end;
$$;

create extension if not exists pg_cron with schema pg_catalog;

create table public.group_schedule_entries (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  start_time time without time zone not null,
  end_time time without time zone not null,
  location_type text not null check (location_type in ('physical', 'online')),
  physical_location text,
  meeting_link text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint group_schedule_entries_same_day check (end_time > start_time),
  constraint group_schedule_entries_location check (
    (location_type = 'physical'
      and physical_location is not null
      and btrim(physical_location) <> ''
      and char_length(physical_location) <= 500
      and meeting_link is null)
    or
    (location_type = 'online'
      and meeting_link is not null
      and btrim(meeting_link) <> ''
      and char_length(meeting_link) <= 2048
      and meeting_link like 'https://%'
      and physical_location is null)
  ),
  unique (id, group_id)
);

create unique index group_schedule_entries_active_slot_uidx
  on public.group_schedule_entries (group_id, weekday, start_time, end_time)
  where is_active;

create index group_schedule_entries_group_weekday_idx
  on public.group_schedule_entries (group_id, weekday);

create table public.class_sessions (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete restrict,
  schedule_entry_id uuid,
  original_date date,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  location_type text not null check (location_type in ('physical', 'online')),
  physical_location text,
  meeting_link text,
  status text not null default 'scheduled'
    check (status in ('scheduled', 'completed', 'cancelled')),
  notes text check (notes is null or char_length(notes) <= 5000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint class_sessions_schedule_pair check (
    (schedule_entry_id is null and original_date is null)
    or (schedule_entry_id is not null and original_date is not null)
  ),
  constraint class_sessions_positive_duration check (ends_at > starts_at),
  constraint class_sessions_location check (
    (location_type = 'physical'
      and physical_location is not null
      and btrim(physical_location) <> ''
      and char_length(physical_location) <= 500
      and meeting_link is null)
    or
    (location_type = 'online'
      and meeting_link is not null
      and btrim(meeting_link) <> ''
      and char_length(meeting_link) <= 2048
      and meeting_link like 'https://%'
      and physical_location is null)
  ),
  constraint class_sessions_schedule_group_fkey
    foreign key (schedule_entry_id, group_id)
    references public.group_schedule_entries (id, group_id)
    on delete restrict,
  unique (id, group_id)
);

create unique index class_sessions_schedule_date_uidx
  on public.class_sessions (schedule_entry_id, original_date)
  where schedule_entry_id is not null;

create index class_sessions_group_starts_idx
  on public.class_sessions (group_id, starts_at);

create index class_sessions_group_status_starts_idx
  on public.class_sessions (group_id, status, starts_at);

create table public.session_attendance (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null,
  group_id uuid not null,
  student_id uuid not null,
  status text not null default 'not_marked'
    check (status in ('not_marked', 'present', 'absent', 'late', 'excused')),
  marked_at timestamptz,
  marked_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint session_attendance_marked_state check (
    (status = 'not_marked' and marked_at is null and marked_by is null)
    or (status <> 'not_marked' and marked_at is not null)
  ),
  constraint session_attendance_session_group_fkey
    foreign key (session_id, group_id)
    references public.class_sessions (id, group_id)
    on delete restrict,
  constraint session_attendance_membership_fkey
    foreign key (group_id, student_id)
    references public.group_memberships (group_id, student_id)
    on delete restrict,
  unique (session_id, student_id)
);

create index session_attendance_group_student_idx
  on public.session_attendance (group_id, student_id);

create index session_attendance_marked_by_idx
  on public.session_attendance (marked_by)
  where marked_by is not null;

create trigger set_group_schedule_entries_updated_at
  before update on public.group_schedule_entries
  for each row execute function private.set_updated_at();

create trigger set_class_sessions_updated_at
  before update on public.class_sessions
  for each row execute function private.set_updated_at();

create trigger set_session_attendance_updated_at
  before update on public.session_attendance
  for each row execute function private.set_updated_at();

alter table public.group_schedule_entries enable row level security;
alter table public.class_sessions enable row level security;
alter table public.session_attendance enable row level security;

revoke all on table public.group_schedule_entries from public, anon, authenticated;
revoke all on table public.class_sessions from public, anon, authenticated;
revoke all on table public.session_attendance from public, anon, authenticated;

grant select on table public.group_schedule_entries to authenticated;
grant insert (
  group_id, weekday, start_time, end_time, location_type,
  physical_location, meeting_link, is_active
) on table public.group_schedule_entries to authenticated;
grant update (
  weekday, start_time, end_time, location_type,
  physical_location, meeting_link, is_active
) on table public.group_schedule_entries to authenticated;
grant delete on table public.group_schedule_entries to authenticated;

grant select on table public.class_sessions to authenticated;
grant update (
  starts_at, ends_at, location_type, physical_location,
  meeting_link, status, notes
) on table public.class_sessions to authenticated;

grant select on table public.session_attendance to authenticated;

grant all on table public.group_schedule_entries to service_role;
grant all on table public.class_sessions to service_role;
grant all on table public.session_attendance to service_role;

create policy "Teachers and approved students can read group schedules"
on public.group_schedule_entries for select to authenticated
using (
  private.owns_group(group_id)
  or private.has_approved_group_session(group_id)
);

create policy "Teachers can create owned group schedules"
on public.group_schedule_entries for insert to authenticated
with check (private.owns_group(group_id));

create policy "Teachers can update owned group schedules"
on public.group_schedule_entries for update to authenticated
using (private.owns_group(group_id))
with check (private.owns_group(group_id));

create policy "Teachers can delete owned group schedules"
on public.group_schedule_entries for delete to authenticated
using (private.owns_group(group_id));

create policy "Teachers and approved students can read class sessions"
on public.class_sessions for select to authenticated
using (
  private.owns_group(group_id)
  or private.has_approved_group_session(group_id)
);

create policy "Teachers can update owned class sessions"
on public.class_sessions for update to authenticated
using (private.owns_group(group_id))
with check (private.owns_group(group_id));

create policy "Teachers and students can read relevant attendance"
on public.session_attendance for select to authenticated
using (
  private.owns_group(group_id)
  or (
    student_id = (select auth.uid())
    and private.has_approved_group_session(group_id)
  )
);

-- A private trigger and a private Cron job are the only callers. The unique
-- occurrence index keeps generation idempotent across concurrent runs.
create function private.fill_class_sessions(p_schedule_id uuid default null)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Africa/Cairo')::date;
  v_inserted integer;
begin
  insert into public.class_sessions (
    group_id, schedule_entry_id, original_date,
    starts_at, ends_at, location_type, physical_location, meeting_link
  )
  select
    entry.group_id,
    entry.id,
    occurrence.day,
    occurrence.starts_at,
    occurrence.ends_at,
    entry.location_type,
    entry.physical_location,
    entry.meeting_link
  from public.group_schedule_entries as entry
  join public.groups as owned_group on owned_group.id = entry.group_id
  cross join lateral (
    select
      (v_today + day_offset) as day,
      (v_today + day_offset + entry.start_time) at time zone 'Africa/Cairo'
        as starts_at,
      (v_today + day_offset + entry.end_time) at time zone 'Africa/Cairo'
        as ends_at
    from generate_series(0, 27) as calendar(day_offset)
    where extract(isodow from v_today + day_offset)::smallint = entry.weekday
  ) as occurrence
  where owned_group.is_active
    and entry.is_active
    and (p_schedule_id is null or entry.id = p_schedule_id)
    and occurrence.starts_at > now()
    and occurrence.ends_at > occurrence.starts_at
  on conflict (schedule_entry_id, original_date)
    where schedule_entry_id is not null do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted;
end;
$$;

create function private.fill_schedule_after_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.is_active then
    perform private.fill_class_sessions(new.id);
  end if;
  return new;
end;
$$;

create trigger fill_group_schedule_entries_after_write
  after insert or update of
    weekday, start_time, end_time, location_type,
    physical_location, meeting_link, is_active
  on public.group_schedule_entries
  for each row execute function private.fill_schedule_after_write();

revoke all on function private.fill_class_sessions(uuid)
  from public, anon, authenticated;
revoke all on function private.fill_schedule_after_write()
  from public, anon, authenticated;

create function public.create_manual_class_session(
  p_group_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_location_type text,
  p_physical_location text default null,
  p_meeting_link text default null,
  p_notes text default null
)
returns public.class_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session public.class_sessions%rowtype;
begin
  if (select auth.uid()) is null or not exists (
    select 1 from public.groups as owned_group
    where owned_group.id = p_group_id
      and owned_group.teacher_id = (select auth.uid())
      and owned_group.is_active
  ) then
    raise exception using errcode = '42501',
      message = 'An active owned group is required';
  end if;

  insert into public.class_sessions (
    group_id, starts_at, ends_at, location_type,
    physical_location, meeting_link, notes
  ) values (
    p_group_id, p_starts_at, p_ends_at, p_location_type,
    p_physical_location, p_meeting_link, p_notes
  ) returning * into v_session;

  return v_session;
end;
$$;

create function public.set_session_attendance(
  p_session_id uuid,
  p_student_id uuid,
  p_status text
)
returns public.session_attendance
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_group_id uuid;
  v_session_status text;
  v_has_record boolean;
  v_attendance public.session_attendance%rowtype;
begin
  if p_status is null or p_status not in (
    'not_marked', 'present', 'absent', 'late', 'excused'
  ) then
    raise exception using errcode = '22023',
      message = 'A valid attendance status is required';
  end if;

  select session.group_id, session.status
  into v_group_id, v_session_status
  from public.class_sessions as session
  where session.id = p_session_id;

  if v_group_id is null or not private.owns_group(v_group_id) then
    raise exception using errcode = '42501',
      message = 'An owned class session is required';
  end if;

  select exists (
    select 1 from public.session_attendance as attendance
    where attendance.session_id = p_session_id
      and attendance.student_id = p_student_id
  ) into v_has_record;

  if not v_has_record and (
    v_session_status = 'cancelled'
    or not exists (
      select 1 from public.group_memberships as membership
      where membership.group_id = v_group_id
        and membership.student_id = p_student_id
        and membership.status = 'active'
    )
  ) then
    raise exception using errcode = '22023',
      message = 'The student is not eligible for new attendance';
  end if;

  insert into public.session_attendance (
    session_id, group_id, student_id, status, marked_at, marked_by
  ) values (
    p_session_id,
    v_group_id,
    p_student_id,
    p_status,
    case when p_status = 'not_marked' then null else now() end,
    case when p_status = 'not_marked' then null else (select auth.uid()) end
  )
  on conflict (session_id, student_id) do update set
    status = excluded.status,
    marked_at = excluded.marked_at,
    marked_by = excluded.marked_by
  returning * into v_attendance;

  return v_attendance;
end;
$$;

create function public.archive_group(p_group_id uuid)
returns public.groups
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_group public.groups%rowtype;
begin
  update public.groups as owned_group
  set is_active = false
  where owned_group.id = p_group_id
    and owned_group.teacher_id = (select auth.uid())
  returning * into v_group;

  if not found then
    raise exception using errcode = '42501',
      message = 'An owned group is required';
  end if;

  return v_group;
end;
$$;

revoke all on function public.create_manual_class_session(
  uuid, timestamptz, timestamptz, text, text, text, text
) from public, anon, authenticated;
revoke all on function public.set_session_attendance(uuid, uuid, text)
  from public, anon, authenticated;
revoke all on function public.archive_group(uuid)
  from public, anon, authenticated;

grant execute on function public.create_manual_class_session(
  uuid, timestamptz, timestamptz, text, text, text, text
) to authenticated;
grant execute on function public.set_session_attendance(uuid, uuid, text)
  to authenticated;
grant execute on function public.archive_group(uuid)
  to authenticated;

-- Cron uses UTC. 00:10 UTC is after the Cairo date boundary year-round;
-- the function derives the actual Cairo calendar date for its window.
grant usage on schema cron to postgres;
grant all privileges on all tables in schema cron to postgres;
select cron.schedule(
  'telmizo_phase3_fill_sessions',
  '10 0 * * *',
  'select private.fill_class_sessions();'
);

commit;
