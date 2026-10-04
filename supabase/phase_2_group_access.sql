begin;

create table if not exists public.student_devices (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  installation_id_hash text not null,
  device_name text not null,
  platform text not null,
  app_version text,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint student_devices_installation_hash_format check (
    installation_id_hash ~ '^[0-9a-f]{64}$'
  ),
  constraint student_devices_name_not_blank check (
    btrim(device_name) <> '' and char_length(device_name) <= 120
  ),
  constraint student_devices_platform_valid check (
    platform in ('android', 'ios')
  ),
  constraint student_devices_app_version_valid check (
    app_version is null
    or (btrim(app_version) <> '' and char_length(app_version) <= 50)
  ),
  unique (student_id, installation_id_hash)
);

create table if not exists public.group_join_requests (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  device_id uuid not null references public.student_devices (id) on delete restrict,
  session_id uuid not null,
  request_type text not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references public.profiles (id) on delete set null,
  constraint group_join_requests_type_valid check (
    request_type in ('join', 'device_replacement')
  ),
  constraint group_join_requests_status_valid check (
    status in ('pending', 'approved', 'rejected')
  ),
  constraint group_join_requests_decision_valid check (
    (status = 'pending' and decided_at is null and decided_by is null)
    or
    (status in ('approved', 'rejected') and decided_at is not null and decided_by is not null)
  )
);

create table if not exists public.group_memberships (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  approved_device_id uuid references public.student_devices (id) on delete restrict,
  approved_session_id uuid,
  status text not null default 'active',
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint group_memberships_status_valid check (
    status in ('active', 'suspended', 'removed')
  ),
  constraint group_memberships_active_device_valid check (
    (status = 'active' and approved_device_id is not null and approved_session_id is not null)
    or status in ('suspended', 'removed')
  ),
  unique (group_id, student_id)
);

create unique index if not exists group_join_requests_one_pending_idx
  on public.group_join_requests (group_id, student_id)
  where status = 'pending';

create index if not exists group_join_requests_teacher_queue_idx
  on public.group_join_requests (group_id, status, created_at desc);

create index if not exists group_join_requests_student_idx
  on public.group_join_requests (student_id, status, created_at desc);

create index if not exists group_memberships_group_status_idx
  on public.group_memberships (group_id, status);

create index if not exists group_memberships_student_status_idx
  on public.group_memberships (student_id, status);

create index if not exists group_memberships_session_idx
  on public.group_memberships (approved_session_id)
  where status = 'active';

drop trigger if exists set_student_devices_updated_at on public.student_devices;
create trigger set_student_devices_updated_at
  before update on public.student_devices
  for each row execute function private.set_updated_at();

drop trigger if exists set_group_join_requests_updated_at on public.group_join_requests;
create trigger set_group_join_requests_updated_at
  before update on public.group_join_requests
  for each row execute function private.set_updated_at();

drop trigger if exists set_group_memberships_updated_at on public.group_memberships;
create trigger set_group_memberships_updated_at
  before update on public.group_memberships
  for each row execute function private.set_updated_at();

create or replace function private.owns_group(p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1
      from public.groups as owned_group
      where owned_group.id = p_group_id
        and owned_group.teacher_id = (select auth.uid())
    );
$$;

create or replace function private.has_approved_group_session(p_group_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and nullif((select auth.jwt()) ->> 'session_id', '') is not null
    and exists (
      select 1
      from public.group_memberships as membership
      where membership.group_id = p_group_id
        and membership.student_id = (select auth.uid())
        and membership.status = 'active'
        and membership.approved_session_id =
          (nullif((select auth.jwt()) ->> 'session_id', ''))::uuid
    );
$$;

create or replace function private.can_teacher_view_student(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and (
      exists (
        select 1
        from public.group_join_requests as request
        join public.groups as owned_group on owned_group.id = request.group_id
        where request.student_id = p_student_id
          and owned_group.teacher_id = (select auth.uid())
      )
      or exists (
        select 1
        from public.group_memberships as membership
        join public.groups as owned_group on owned_group.id = membership.group_id
        where membership.student_id = p_student_id
          and owned_group.teacher_id = (select auth.uid())
      )
    );
$$;

create or replace function private.can_student_view_teacher(p_teacher_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and nullif((select auth.jwt()) ->> 'session_id', '') is not null
    and exists (
      select 1
      from public.group_memberships as membership
      join public.groups as joined_group on joined_group.id = membership.group_id
      where membership.student_id = (select auth.uid())
        and membership.status = 'active'
        and membership.approved_session_id =
          (nullif((select auth.jwt()) ->> 'session_id', ''))::uuid
        and joined_group.teacher_id = p_teacher_id
    );
$$;

create or replace function public.request_group_access(
  p_invite_code text,
  p_installation_id text,
  p_device_name text,
  p_platform text,
  p_app_version text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := (select auth.uid());
  v_session_id_text text := nullif((select auth.jwt()) ->> 'session_id', '');
  v_session_id uuid;
  v_group_id uuid;
  v_teacher_id uuid;
  v_device_id uuid;
  v_membership public.group_memberships%rowtype;
  v_request_id uuid;
  v_request_type text;
  v_installation_hash text;
begin
  if v_student_id is null or v_session_id_text is null then
    raise exception using errcode = '42501', message = 'Authentication with an active session is required';
  end if;

  begin
    v_session_id := v_session_id_text::uuid;
  exception when invalid_text_representation then
    raise exception using errcode = '42501', message = 'The authenticated session is invalid';
  end;

  if p_invite_code is null
    or btrim(p_invite_code) = ''
    or char_length(btrim(p_invite_code)) > 100
  then
    raise exception using errcode = '22023', message = 'A valid invite code is required';
  end if;

  if p_installation_id is null
    or char_length(p_installation_id) < 16
    or char_length(p_installation_id) > 200
  then
    raise exception using errcode = '22023', message = 'A valid installation identifier is required';
  end if;

  if p_device_name is null
    or btrim(p_device_name) = ''
    or char_length(btrim(p_device_name)) > 120
  then
    raise exception using errcode = '22023', message = 'A valid device name is required';
  end if;

  if lower(btrim(coalesce(p_platform, ''))) not in ('android', 'ios') then
    raise exception using errcode = '22023', message = 'The device platform is not supported';
  end if;

  if p_app_version is not null
    and (btrim(p_app_version) = '' or char_length(btrim(p_app_version)) > 50)
  then
    raise exception using errcode = '22023', message = 'The app version is invalid';
  end if;

  select joined_group.id, joined_group.teacher_id
  into v_group_id, v_teacher_id
  from public.groups as joined_group
  where joined_group.invite_code = btrim(p_invite_code)
    and joined_group.is_active
  for update;

  if v_group_id is null then
    raise exception using errcode = 'P0002', message = 'The invite code is invalid or the group is inactive';
  end if;

  if v_teacher_id = v_student_id then
    raise exception using errcode = '42501', message = 'A teacher cannot join their own group as a student';
  end if;

  v_installation_hash := encode(
    sha256(convert_to(p_installation_id, 'UTF8')),
    'hex'
  );

  insert into public.student_devices (
    student_id,
    installation_id_hash,
    device_name,
    platform,
    app_version,
    last_seen_at
  )
  values (
    v_student_id,
    v_installation_hash,
    btrim(p_device_name),
    lower(btrim(p_platform)),
    nullif(btrim(p_app_version), ''),
    now()
  )
  on conflict (student_id, installation_id_hash)
  do update set
    device_name = excluded.device_name,
    platform = excluded.platform,
    app_version = excluded.app_version,
    last_seen_at = now()
  returning id into v_device_id;

  select membership.*
  into v_membership
  from public.group_memberships as membership
  where membership.group_id = v_group_id
    and membership.student_id = v_student_id
  for update;

  if found
    and v_membership.status = 'active'
    and v_membership.approved_device_id = v_device_id
  then
    update public.group_memberships
    set approved_session_id = v_session_id
    where id = v_membership.id;

    return jsonb_build_object(
      'status', 'approved',
      'request_type', 'existing_device',
      'request_id', null,
      'membership_id', v_membership.id
    );
  end if;

  v_request_type := case
    when found then 'device_replacement'
    else 'join'
  end;

  select request.id
  into v_request_id
  from public.group_join_requests as request
  where request.group_id = v_group_id
    and request.student_id = v_student_id
    and request.status = 'pending'
  for update;

  if v_request_id is null then
    insert into public.group_join_requests (
      group_id,
      student_id,
      device_id,
      session_id,
      request_type
    )
    values (
      v_group_id,
      v_student_id,
      v_device_id,
      v_session_id,
      v_request_type
    )
    returning id into v_request_id;
  else
    update public.group_join_requests
    set device_id = v_device_id,
        session_id = v_session_id,
        request_type = v_request_type,
        created_at = now()
    where id = v_request_id;
  end if;

  return jsonb_build_object(
    'status', 'pending',
    'request_type', v_request_type,
    'request_id', v_request_id,
    'membership_id', case when found then v_membership.id else null end
  );
end;
$$;

create or replace function public.decide_group_access_request(
  p_request_id uuid,
  p_approve boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_teacher_id uuid := (select auth.uid());
  v_request public.group_join_requests%rowtype;
  v_membership_id uuid;
begin
  if v_teacher_id is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;

  select request.*
  into v_request
  from public.group_join_requests as request
  join public.groups as owned_group on owned_group.id = request.group_id
  where request.id = p_request_id
    and request.status = 'pending'
    and owned_group.teacher_id = v_teacher_id
  for update of request;

  if not found then
    raise exception using errcode = '42501', message = 'The request is unavailable';
  end if;

  if p_approve then
    insert into public.group_memberships (
      group_id,
      student_id,
      approved_device_id,
      approved_session_id,
      status
    )
    values (
      v_request.group_id,
      v_request.student_id,
      v_request.device_id,
      v_request.session_id,
      'active'
    )
    on conflict (group_id, student_id)
    do update set
      approved_device_id = excluded.approved_device_id,
      approved_session_id = excluded.approved_session_id,
      status = 'active'
    returning id into v_membership_id;

    update public.group_join_requests
    set status = 'approved',
        decided_at = now(),
        decided_by = v_teacher_id
    where id = v_request.id;

    update public.group_join_requests
    set status = 'rejected',
        decided_at = now(),
        decided_by = v_teacher_id
    where group_id = v_request.group_id
      and student_id = v_request.student_id
      and status = 'pending'
      and id <> v_request.id;

    return jsonb_build_object(
      'status', 'approved',
      'request_id', v_request.id,
      'membership_id', v_membership_id,
      'replaced_previous_device', v_request.request_type = 'device_replacement'
    );
  end if;

  update public.group_join_requests
  set status = 'rejected',
      decided_at = now(),
      decided_by = v_teacher_id
  where id = v_request.id;

  return jsonb_build_object(
    'status', 'rejected',
    'request_id', v_request.id,
    'membership_id', null,
    'replaced_previous_device', false
  );
end;
$$;

create or replace function public.revoke_group_member_access(p_membership_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;

  update public.group_memberships as membership
  set status = 'suspended',
      approved_session_id = null
  from public.groups as owned_group
  where membership.id = p_membership_id
    and owned_group.id = membership.group_id
    and owned_group.teacher_id = (select auth.uid());

  if not found then
    raise exception using errcode = '42501', message = 'The membership is unavailable';
  end if;
end;
$$;

create or replace function public.leave_group(p_membership_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception using errcode = '42501', message = 'Authentication is required';
  end if;

  update public.group_memberships
  set status = 'removed',
      approved_session_id = null
  where id = p_membership_id
    and student_id = (select auth.uid());

  if not found then
    raise exception using errcode = '42501', message = 'The membership is unavailable';
  end if;
end;
$$;

revoke all on function private.owns_group(uuid) from public;
revoke all on function private.owns_group(uuid) from anon;
revoke all on function private.has_approved_group_session(uuid) from public;
revoke all on function private.has_approved_group_session(uuid) from anon;
revoke all on function private.can_teacher_view_student(uuid) from public;
revoke all on function private.can_teacher_view_student(uuid) from anon;
revoke all on function private.can_student_view_teacher(uuid) from public;
revoke all on function private.can_student_view_teacher(uuid) from anon;

grant usage on schema private to authenticated;
grant execute on function private.owns_group(uuid) to authenticated;
grant execute on function private.has_approved_group_session(uuid) to authenticated;
grant execute on function private.can_teacher_view_student(uuid) to authenticated;
grant execute on function private.can_student_view_teacher(uuid) to authenticated;

revoke all on function public.request_group_access(text, text, text, text, text) from public;
revoke all on function public.request_group_access(text, text, text, text, text) from anon;
grant execute on function public.request_group_access(text, text, text, text, text) to authenticated;

revoke all on function public.decide_group_access_request(uuid, boolean) from public;
revoke all on function public.decide_group_access_request(uuid, boolean) from anon;
grant execute on function public.decide_group_access_request(uuid, boolean) to authenticated;

revoke all on function public.revoke_group_member_access(uuid) from public;
revoke all on function public.revoke_group_member_access(uuid) from anon;
grant execute on function public.revoke_group_member_access(uuid) to authenticated;

revoke all on function public.leave_group(uuid) from public;
revoke all on function public.leave_group(uuid) from anon;
grant execute on function public.leave_group(uuid) to authenticated;

alter table public.student_devices enable row level security;
alter table public.group_join_requests enable row level security;
alter table public.group_memberships enable row level security;

revoke all on table public.student_devices from anon;
revoke all on table public.student_devices from authenticated;
revoke all on table public.group_join_requests from anon;
revoke all on table public.group_join_requests from authenticated;
revoke all on table public.group_memberships from anon;
revoke all on table public.group_memberships from authenticated;

grant select on table public.student_devices to authenticated;
grant select on table public.group_join_requests to authenticated;
grant select on table public.group_memberships to authenticated;

grant all on table public.student_devices to service_role;
grant all on table public.group_join_requests to service_role;
grant all on table public.group_memberships to service_role;

drop policy if exists "Students and teachers can read relevant devices"
  on public.student_devices;
create policy "Students and teachers can read relevant devices"
on public.student_devices
for select
to authenticated
using (
  student_id = (select auth.uid())
  or exists (
    select 1
    from public.group_join_requests as request
    where request.device_id = student_devices.id
      and private.owns_group(request.group_id)
  )
  or exists (
    select 1
    from public.group_memberships as membership
    where membership.approved_device_id = student_devices.id
      and private.owns_group(membership.group_id)
  )
);

drop policy if exists "Students and teachers can read relevant requests"
  on public.group_join_requests;
create policy "Students and teachers can read relevant requests"
on public.group_join_requests
for select
to authenticated
using (
  student_id = (select auth.uid())
  or private.owns_group(group_id)
);

drop policy if exists "Approved students and teachers can read memberships"
  on public.group_memberships;
create policy "Approved students and teachers can read memberships"
on public.group_memberships
for select
to authenticated
using (
  private.owns_group(group_id)
  or (
    student_id = (select auth.uid())
    and status = 'active'
    and approved_session_id =
      (nullif((select auth.jwt()) ->> 'session_id', ''))::uuid
  )
);

drop policy if exists "Approved students can read their groups"
  on public.groups;
create policy "Approved students can read their groups"
on public.groups
for select
to authenticated
using (private.has_approved_group_session(id));

drop policy if exists "Teachers can read relevant student profiles"
  on public.profiles;
create policy "Teachers can read relevant student profiles"
on public.profiles
for select
to authenticated
using (private.can_teacher_view_student(id));

drop policy if exists "Approved students can read their teachers"
  on public.profiles;
create policy "Approved students can read their teachers"
on public.profiles
for select
to authenticated
using (private.can_student_view_teacher(id));

do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'group_join_requests'
  ) then
    alter publication supabase_realtime add table public.group_join_requests;
  end if;

  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'group_memberships'
  ) then
    alter publication supabase_realtime add table public.group_memberships;
  end if;
end;
$$;

commit;
