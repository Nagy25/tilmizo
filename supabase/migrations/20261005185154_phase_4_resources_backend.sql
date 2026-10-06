begin;

do $$
begin
  if to_regclass('public.groups') is null
    or to_regclass('public.class_sessions') is null
    or to_regclass('public.group_memberships') is null
    or to_regclass('public.profiles') is null then
    raise exception 'Phase 4 requires the Phase 1-3 schema';
  end if;
end;
$$;

create extension if not exists pg_net with schema extensions;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.groups'::regclass
      and conname = 'groups_id_teacher_id_key'
  ) then
    alter table public.groups
      add constraint groups_id_teacher_id_key unique (id, teacher_id);
  end if;
end;
$$;

create table public.resources (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null,
  teacher_id uuid not null,
  session_id uuid,
  title text not null,
  description text,
  type text not null check (
    type in (
      'pdf', 'image', 'file', 'uploaded_video',
      'external_link', 'video_link'
    )
  ),
  storage_path text unique,
  file_name text,
  file_size bigint,
  mime_type text,
  external_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint resources_group_teacher_fkey
    foreign key (group_id, teacher_id)
    references public.groups (id, teacher_id)
    on delete restrict,
  constraint resources_session_group_fkey
    foreign key (session_id, group_id)
    references public.class_sessions (id, group_id)
    on delete restrict,
  constraint resources_title_valid check (
    btrim(title) <> '' and char_length(title) <= 200
  ),
  constraint resources_description_valid check (
    description is null or char_length(description) <= 5000
  ),
  constraint resources_uploaded_or_link_valid check (
    (
      type in ('pdf', 'image', 'file', 'uploaded_video')
      and storage_path is not null
      and btrim(storage_path) <> ''
      and file_name is not null
      and btrim(file_name) <> ''
      and char_length(file_name) <= 255
      and file_size is not null
      and file_size > 0
      and mime_type is not null
      and btrim(mime_type) <> ''
      and external_url is null
    )
    or
    (
      type in ('external_link', 'video_link')
      and external_url is not null
      and external_url ~ '^https://[^[:space:]]+$'
      and char_length(external_url) <= 2048
      and storage_path is null
      and file_name is null
      and file_size is null
      and mime_type is null
    )
  )
);

create index resources_group_created_at_idx
  on public.resources (group_id, created_at desc);
create index resources_teacher_created_at_idx
  on public.resources (teacher_id, created_at desc);
create index resources_session_created_at_idx
  on public.resources (session_id, created_at desc)
  where session_id is not null;

create trigger set_resources_updated_at
  before update on public.resources
  for each row execute function private.set_updated_at();

create table private.resource_plans (
  plan_key text primary key,
  quota_bytes bigint not null check (quota_bytes > 0),
  pdf_file_max_bytes bigint not null check (pdf_file_max_bytes > 0),
  image_max_bytes bigint not null check (image_max_bytes > 0),
  video_max_bytes bigint not null check (video_max_bytes > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into private.resource_plans (
  plan_key,
  quota_bytes,
  pdf_file_max_bytes,
  image_max_bytes,
  video_max_bytes
) values (
  'default',
  1073741824,
  26214400,
  10485760,
  52428800
);

create table private.teacher_resource_plans (
  teacher_id uuid primary key references public.profiles (id) on delete cascade,
  plan_key text not null references private.resource_plans (plan_key)
    on update cascade on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table private.teacher_storage_usage (
  teacher_id uuid primary key references public.profiles (id) on delete cascade,
  committed_bytes bigint not null default 0 check (committed_bytes >= 0),
  reserved_bytes bigint not null default 0 check (reserved_bytes >= 0),
  updated_at timestamptz not null default now()
);

create table private.resource_upload_reservations (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  group_id uuid not null,
  session_id uuid,
  title text not null,
  description text,
  resource_type text not null check (
    resource_type in ('pdf', 'image', 'file', 'uploaded_video')
  ),
  storage_path text not null unique,
  file_name text not null,
  declared_size bigint not null check (declared_size > 0),
  declared_mime_type text not null,
  actual_size bigint,
  actual_mime_type text,
  status text not null default 'pending' check (
    status in ('pending', 'cancelled', 'finalized', 'expired')
  ),
  failure_reason text,
  expires_at timestamptz not null default (now() + interval '25 hours'),
  quota_released_at timestamptz,
  finalized_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint resource_uploads_group_teacher_fkey
    foreign key (group_id, teacher_id)
    references public.groups (id, teacher_id)
    on delete restrict,
  constraint resource_uploads_session_group_fkey
    foreign key (session_id, group_id)
    references public.class_sessions (id, group_id)
    on delete restrict
);

create index resource_uploads_cleanup_idx
  on private.resource_upload_reservations (expires_at)
  where status in ('pending', 'cancelled') and quota_released_at is null;
create index resource_uploads_teacher_status_idx
  on private.resource_upload_reservations (teacher_id, status);

create table private.resource_deletion_jobs (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  storage_path text not null unique,
  file_size bigint not null check (file_size > 0),
  status text not null default 'pending' check (
    status in ('pending', 'completed')
  ),
  attempts integer not null default 0 check (attempts >= 0),
  last_error text,
  available_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index resource_deletion_jobs_pending_idx
  on private.resource_deletion_jobs (available_at, created_at)
  where status = 'pending';

create trigger set_resource_plans_updated_at
  before update on private.resource_plans
  for each row execute function private.set_updated_at();
create trigger set_teacher_resource_plans_updated_at
  before update on private.teacher_resource_plans
  for each row execute function private.set_updated_at();
create trigger set_resource_uploads_updated_at
  before update on private.resource_upload_reservations
  for each row execute function private.set_updated_at();
create trigger set_resource_deletion_jobs_updated_at
  before update on private.resource_deletion_jobs
  for each row execute function private.set_updated_at();

alter table public.resources enable row level security;
alter table private.resource_plans enable row level security;
alter table private.teacher_resource_plans enable row level security;
alter table private.teacher_storage_usage enable row level security;
alter table private.resource_upload_reservations enable row level security;
alter table private.resource_deletion_jobs enable row level security;

revoke all on table public.resources from public, anon, authenticated;
grant select on table public.resources to authenticated;
grant all on table public.resources to service_role;

revoke all on table private.resource_plans from public, anon, authenticated;
revoke all on table private.teacher_resource_plans from public, anon, authenticated;
revoke all on table private.teacher_storage_usage from public, anon, authenticated;
revoke all on table private.resource_upload_reservations
  from public, anon, authenticated;
revoke all on table private.resource_deletion_jobs
  from public, anon, authenticated;
grant usage on schema private to service_role;
grant all on table private.resource_plans to service_role;
grant all on table private.teacher_resource_plans to service_role;
grant all on table private.teacher_storage_usage to service_role;
grant all on table private.resource_upload_reservations to service_role;
grant all on table private.resource_deletion_jobs to service_role;

create policy "Teachers and approved students can read resources"
on public.resources
for select
to authenticated
using (
  private.owns_group(group_id)
  or private.has_approved_group_session(group_id)
);

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
) values (
  'group-resources', 'group-resources', false, 52428800, null
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Authenticated group resource downloads"
  on storage.objects;
create policy "Authenticated group resource downloads"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'group-resources'
  and exists (
    select 1
    from public.resources as resource
    where resource.storage_path = storage.objects.name
      and (
        private.owns_group(resource.group_id)
        or private.has_approved_group_session(resource.group_id)
      )
  )
);

create function private.resource_limits_for_teacher(p_teacher_id uuid)
returns table (
  quota_bytes bigint,
  pdf_file_max_bytes bigint,
  image_max_bytes bigint,
  video_max_bytes bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    selected_plan.quota_bytes,
    selected_plan.pdf_file_max_bytes,
    selected_plan.image_max_bytes,
    selected_plan.video_max_bytes
  from private.resource_plans as selected_plan
  where selected_plan.plan_key = coalesce(
    (
      select assignment.plan_key
      from private.teacher_resource_plans as assignment
      where assignment.teacher_id = p_teacher_id
    ),
    'default'
  );
$$;

revoke all on function private.resource_limits_for_teacher(uuid)
  from public, anon, authenticated;

create function public.create_external_resource(
  p_group_id uuid,
  p_title text,
  p_type text,
  p_external_url text,
  p_description text default null,
  p_session_id uuid default null
)
returns public.resources
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_teacher_id uuid := (select auth.uid());
  v_resource public.resources%rowtype;
begin
  if v_teacher_id is null or not private.owns_active_group(p_group_id) then
    raise exception using errcode = '42501',
      message = 'An active owned group is required';
  end if;

  if p_type is null or p_type not in ('external_link', 'video_link') then
    raise exception using errcode = '22023',
      message = 'A valid external resource type is required';
  end if;

  if p_title is null or btrim(p_title) = ''
    or char_length(btrim(p_title)) > 200 then
    raise exception using errcode = '22023',
      message = 'A title of at most 200 characters is required';
  end if;

  if p_description is not null and char_length(p_description) > 5000 then
    raise exception using errcode = '22023',
      message = 'The description is too long';
  end if;

  if p_external_url is null
    or p_external_url !~ '^https://[^[:space:]]+$'
    or char_length(p_external_url) > 2048 then
    raise exception using errcode = '22023',
      message = 'A valid HTTPS URL is required';
  end if;

  if p_session_id is not null and not exists (
    select 1
    from public.class_sessions as class_session
    where class_session.id = p_session_id
      and class_session.group_id = p_group_id
  ) then
    raise exception using errcode = '22023',
      message = 'The selected session does not belong to the group';
  end if;

  insert into public.resources (
    group_id, teacher_id, session_id, title, description, type, external_url
  ) values (
    p_group_id,
    v_teacher_id,
    p_session_id,
    btrim(p_title),
    nullif(btrim(p_description), ''),
    p_type,
    p_external_url
  )
  returning * into v_resource;

  return v_resource;
end;
$$;

create function public.update_resource_metadata(
  p_resource_id uuid,
  p_title text,
  p_description text default null,
  p_session_id uuid default null,
  p_external_url text default null
)
returns public.resources
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_teacher_id uuid := (select auth.uid());
  v_existing public.resources%rowtype;
  v_resource public.resources%rowtype;
begin
  select resource.*
  into v_existing
  from public.resources as resource
  where resource.id = p_resource_id
  for update;

  if not found
    or v_teacher_id is null
    or v_existing.teacher_id <> v_teacher_id
    or not private.owns_active_group(v_existing.group_id) then
    raise exception using errcode = '42501',
      message = 'An active owned resource is required';
  end if;

  if p_title is null or btrim(p_title) = ''
    or char_length(btrim(p_title)) > 200 then
    raise exception using errcode = '22023',
      message = 'A title of at most 200 characters is required';
  end if;

  if p_description is not null and char_length(p_description) > 5000 then
    raise exception using errcode = '22023',
      message = 'The description is too long';
  end if;

  if p_session_id is not null and not exists (
    select 1
    from public.class_sessions as class_session
    where class_session.id = p_session_id
      and class_session.group_id = v_existing.group_id
  ) then
    raise exception using errcode = '22023',
      message = 'The selected session does not belong to the group';
  end if;

  if v_existing.type in ('external_link', 'video_link') then
    if p_external_url is null
      or p_external_url !~ '^https://[^[:space:]]+$'
      or char_length(p_external_url) > 2048 then
      raise exception using errcode = '22023',
        message = 'A valid HTTPS URL is required';
    end if;
  elsif p_external_url is not null then
    raise exception using errcode = '22023',
      message = 'Uploaded resource content is immutable';
  end if;

  update public.resources as resource
  set
    title = btrim(p_title),
    description = nullif(btrim(p_description), ''),
    session_id = p_session_id,
    external_url = case
      when resource.type in ('external_link', 'video_link')
        then p_external_url
      else null
    end
  where resource.id = p_resource_id
  returning * into v_resource;

  return v_resource;
end;
$$;

create function public.reserve_resource_upload(
  p_teacher_id uuid,
  p_group_id uuid,
  p_title text,
  p_resource_type text,
  p_file_name text,
  p_declared_size bigint,
  p_declared_mime_type text,
  p_description text default null,
  p_session_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reservation_id uuid := gen_random_uuid();
  v_extension text;
  v_storage_path text;
  v_max_bytes bigint;
  v_limits record;
  v_usage private.teacher_storage_usage%rowtype;
begin
  if p_teacher_id is null or not exists (
    select 1
    from public.groups as owned_group
    where owned_group.id = p_group_id
      and owned_group.teacher_id = p_teacher_id
      and owned_group.is_active
  ) then
    raise exception using errcode = '42501',
      message = 'An active owned group is required';
  end if;

  if p_resource_type is null
    or p_resource_type not in ('pdf', 'image', 'file', 'uploaded_video') then
    raise exception using errcode = '22023',
      message = 'A valid uploaded resource type is required';
  end if;

  if p_title is null or btrim(p_title) = ''
    or char_length(btrim(p_title)) > 200 then
    raise exception using errcode = '22023',
      message = 'A title of at most 200 characters is required';
  end if;

  if p_description is not null and char_length(p_description) > 5000 then
    raise exception using errcode = '22023',
      message = 'The description is too long';
  end if;

  if p_file_name is null or btrim(p_file_name) = ''
    or char_length(btrim(p_file_name)) > 255 then
    raise exception using errcode = '22023',
      message = 'A file name of at most 255 characters is required';
  end if;

  if p_declared_size is null or p_declared_size <= 0 then
    raise exception using errcode = '22023',
      message = 'A positive file size is required';
  end if;

  if p_declared_mime_type is null or btrim(p_declared_mime_type) = '' then
    raise exception using errcode = '22023',
      message = 'A MIME type is required';
  end if;

  if p_resource_type = 'pdf'
    and lower(btrim(p_declared_mime_type)) <> 'application/pdf' then
    raise exception using errcode = '22023', message = 'PDF MIME type required';
  elsif p_resource_type = 'image'
    and lower(btrim(p_declared_mime_type)) not like 'image/%' then
    raise exception using errcode = '22023', message = 'Image MIME type required';
  elsif p_resource_type = 'uploaded_video'
    and lower(btrim(p_declared_mime_type)) <> 'video/mp4' then
    raise exception using errcode = '22023', message = 'MP4 MIME type required';
  end if;

  if p_session_id is not null and not exists (
    select 1
    from public.class_sessions as class_session
    where class_session.id = p_session_id
      and class_session.group_id = p_group_id
  ) then
    raise exception using errcode = '22023',
      message = 'The selected session does not belong to the group';
  end if;

  select * into v_limits
  from private.resource_limits_for_teacher(p_teacher_id);

  if v_limits.quota_bytes is null then
    raise exception using errcode = '55000',
      message = 'Resource storage limits are not configured';
  end if;

  v_max_bytes := case p_resource_type
    when 'image' then v_limits.image_max_bytes
    when 'uploaded_video' then v_limits.video_max_bytes
    else v_limits.pdf_file_max_bytes
  end;

  if p_declared_size > v_max_bytes then
    raise exception using errcode = '22023',
      message = 'The file exceeds the configured type limit';
  end if;

  v_extension := lower(substring(btrim(p_file_name) from '\.([a-zA-Z0-9]{1,10})$'));
  if v_extension is not null then
    v_extension := '.' || v_extension;
  else
    v_extension := '';
  end if;

  if p_resource_type = 'pdf' and v_extension <> '.pdf' then
    raise exception using errcode = '22023', message = 'A .pdf file is required';
  elsif p_resource_type = 'uploaded_video' and v_extension <> '.mp4' then
    raise exception using errcode = '22023', message = 'An .mp4 file is required';
  end if;

  v_storage_path := p_teacher_id::text || '/' || p_group_id::text || '/'
    || v_reservation_id::text || v_extension;

  insert into private.teacher_storage_usage (teacher_id)
  values (p_teacher_id)
  on conflict (teacher_id) do nothing;

  select * into v_usage
  from private.teacher_storage_usage as usage
  where usage.teacher_id = p_teacher_id
  for update;

  if v_usage.committed_bytes + v_usage.reserved_bytes + p_declared_size
    > v_limits.quota_bytes then
    raise exception using errcode = '22023',
      message = 'The teacher storage quota would be exceeded';
  end if;

  update private.teacher_storage_usage
  set
    reserved_bytes = reserved_bytes + p_declared_size,
    updated_at = now()
  where teacher_id = p_teacher_id;

  insert into private.resource_upload_reservations (
    id, teacher_id, group_id, session_id, title, description,
    resource_type, storage_path, file_name, declared_size,
    declared_mime_type
  ) values (
    v_reservation_id,
    p_teacher_id,
    p_group_id,
    p_session_id,
    btrim(p_title),
    nullif(btrim(p_description), ''),
    p_resource_type,
    v_storage_path,
    btrim(p_file_name),
    p_declared_size,
    lower(btrim(p_declared_mime_type))
  );

  return jsonb_build_object(
    'reservation_id', v_reservation_id,
    'bucket', 'group-resources',
    'storage_path', v_storage_path,
    'expires_at', now() + interval '25 hours',
    'declared_size', p_declared_size
  );
end;
$$;

create function public.get_resource_upload_reservation(
  p_teacher_id uuid,
  p_reservation_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select to_jsonb(reservation)
  from private.resource_upload_reservations as reservation
  where reservation.id = p_reservation_id
    and reservation.teacher_id = p_teacher_id;
$$;

create function public.finalize_resource_upload(
  p_teacher_id uuid,
  p_reservation_id uuid,
  p_actual_size bigint,
  p_actual_mime_type text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reservation private.resource_upload_reservations%rowtype;
  v_limits record;
  v_usage private.teacher_storage_usage%rowtype;
  v_max_bytes bigint;
  v_resource public.resources%rowtype;
begin
  select * into v_reservation
  from private.resource_upload_reservations as reservation
  where reservation.id = p_reservation_id
    and reservation.teacher_id = p_teacher_id
  for update;

  if not found then
    raise exception using errcode = '42501',
      message = 'The upload reservation is not available';
  end if;

  if v_reservation.status = 'finalized' then
    select * into v_resource
    from public.resources as resource
    where resource.id = v_reservation.id;
    return to_jsonb(v_resource);
  end if;

  if v_reservation.status <> 'pending'
    or v_reservation.quota_released_at is not null
    or v_reservation.expires_at <= now() then
    raise exception using errcode = '55000',
      message = 'The upload reservation has expired or was cancelled';
  end if;

  if not exists (
    select 1
    from public.groups as owned_group
    where owned_group.id = v_reservation.group_id
      and owned_group.teacher_id = p_teacher_id
      and owned_group.is_active
  ) then
    raise exception using errcode = '42501',
      message = 'The resource group is no longer active';
  end if;

  if p_actual_size is null or p_actual_size <= 0
    or p_actual_mime_type is null or btrim(p_actual_mime_type) = '' then
    raise exception using errcode = '22023',
      message = 'Valid stored object metadata is required';
  end if;

  select * into v_limits
  from private.resource_limits_for_teacher(p_teacher_id);

  v_max_bytes := case v_reservation.resource_type
    when 'image' then v_limits.image_max_bytes
    when 'uploaded_video' then v_limits.video_max_bytes
    else v_limits.pdf_file_max_bytes
  end;

  if p_actual_size > v_max_bytes then
    raise exception using errcode = '22023',
      message = 'The stored file exceeds the configured type limit';
  end if;

  if v_reservation.resource_type = 'pdf'
    and lower(btrim(p_actual_mime_type)) <> 'application/pdf' then
    raise exception using errcode = '22023', message = 'PDF MIME type required';
  elsif v_reservation.resource_type = 'image'
    and lower(btrim(p_actual_mime_type)) not like 'image/%' then
    raise exception using errcode = '22023', message = 'Image MIME type required';
  elsif v_reservation.resource_type = 'uploaded_video'
    and lower(btrim(p_actual_mime_type)) <> 'video/mp4' then
    raise exception using errcode = '22023', message = 'MP4 MIME type required';
  end if;

  select * into v_usage
  from private.teacher_storage_usage as usage
  where usage.teacher_id = p_teacher_id
  for update;

  if v_usage.committed_bytes + v_usage.reserved_bytes
    - v_reservation.declared_size + p_actual_size > v_limits.quota_bytes then
    raise exception using errcode = '22023',
      message = 'The actual file size exceeds the remaining teacher quota';
  end if;

  insert into public.resources (
    id, group_id, teacher_id, session_id, title, description, type,
    storage_path, file_name, file_size, mime_type
  ) values (
    v_reservation.id,
    v_reservation.group_id,
    v_reservation.teacher_id,
    v_reservation.session_id,
    v_reservation.title,
    v_reservation.description,
    v_reservation.resource_type,
    v_reservation.storage_path,
    v_reservation.file_name,
    p_actual_size,
    lower(btrim(p_actual_mime_type))
  )
  returning * into v_resource;

  update private.teacher_storage_usage
  set
    reserved_bytes = reserved_bytes - v_reservation.declared_size,
    committed_bytes = committed_bytes + p_actual_size,
    updated_at = now()
  where teacher_id = p_teacher_id;

  update private.resource_upload_reservations
  set
    actual_size = p_actual_size,
    actual_mime_type = lower(btrim(p_actual_mime_type)),
    status = 'finalized',
    finalized_at = now(),
    quota_released_at = now()
  where id = p_reservation_id;

  return to_jsonb(v_resource);
end;
$$;

create function public.cancel_resource_upload(
  p_teacher_id uuid,
  p_reservation_id uuid,
  p_reason text default null,
  p_release_immediately boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reservation private.resource_upload_reservations%rowtype;
begin
  select * into v_reservation
  from private.resource_upload_reservations as reservation
  where reservation.id = p_reservation_id
    and reservation.teacher_id = p_teacher_id
  for update;

  if not found then
    raise exception using errcode = '42501',
      message = 'The upload reservation is not available';
  end if;

  if v_reservation.status = 'finalized' then
    raise exception using errcode = '55000',
      message = 'A finalized upload cannot be cancelled';
  end if;

  if v_reservation.quota_released_at is null and p_release_immediately then
    update private.teacher_storage_usage
    set
      reserved_bytes = greatest(0, reserved_bytes - v_reservation.declared_size),
      updated_at = now()
    where teacher_id = p_teacher_id;
  end if;

  update private.resource_upload_reservations
  set
    status = 'cancelled',
    failure_reason = left(nullif(btrim(p_reason), ''), 1000),
    quota_released_at = case
      when p_release_immediately then coalesce(quota_released_at, now())
      else quota_released_at
    end
  where id = p_reservation_id;

  return jsonb_build_object(
    'reservation_id', p_reservation_id,
    'storage_path', v_reservation.storage_path,
    'expires_at', v_reservation.expires_at,
    'quota_released', p_release_immediately
  );
end;
$$;

create function public.prepare_resource_deletion(
  p_teacher_id uuid,
  p_resource_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_resource public.resources%rowtype;
  v_job_id uuid;
begin
  select * into v_resource
  from public.resources as resource
  where resource.id = p_resource_id
  for update;

  if not found
    or v_resource.teacher_id <> p_teacher_id
    or not exists (
      select 1
      from public.groups as owned_group
      where owned_group.id = v_resource.group_id
        and owned_group.teacher_id = p_teacher_id
        and owned_group.is_active
    ) then
    raise exception using errcode = '42501',
      message = 'An active owned resource is required';
  end if;

  if v_resource.storage_path is not null then
    insert into private.resource_deletion_jobs (
      teacher_id, storage_path, file_size
    ) values (
      p_teacher_id, v_resource.storage_path, v_resource.file_size
    ) returning id into v_job_id;
  end if;

  delete from public.resources where id = p_resource_id;

  return jsonb_build_object(
    'deleted', true,
    'job_id', v_job_id,
    'storage_path', v_resource.storage_path
  );
end;
$$;

create function public.list_resource_cleanup_work(p_limit integer default 100)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'reservations', coalesce((
      select jsonb_agg(to_jsonb(expired_upload))
      from (
        select reservation.id, reservation.teacher_id,
          reservation.storage_path, reservation.declared_size
        from private.resource_upload_reservations as reservation
        where reservation.status in ('pending', 'cancelled')
          and reservation.quota_released_at is null
          and reservation.expires_at <= now()
        order by reservation.expires_at
        limit greatest(1, least(coalesce(p_limit, 100), 500))
      ) as expired_upload
    ), '[]'::jsonb),
    'deletions', coalesce((
      select jsonb_agg(to_jsonb(pending_deletion))
      from (
        select job.id, job.teacher_id, job.storage_path, job.file_size
        from private.resource_deletion_jobs as job
        where job.status = 'pending'
          and job.available_at <= now()
        order by job.created_at
        limit greatest(1, least(coalesce(p_limit, 100), 500))
      ) as pending_deletion
    ), '[]'::jsonb)
  );
$$;

create function public.complete_resource_reservation_cleanup(
  p_reservation_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reservation private.resource_upload_reservations%rowtype;
begin
  select * into v_reservation
  from private.resource_upload_reservations as reservation
  where reservation.id = p_reservation_id
  for update;

  if not found or v_reservation.quota_released_at is not null then
    return;
  end if;

  if v_reservation.status = 'finalized'
    or v_reservation.expires_at > now() then
    raise exception using errcode = '55000',
      message = 'The reservation is not ready for cleanup';
  end if;

  update private.teacher_storage_usage
  set
    reserved_bytes = greatest(0, reserved_bytes - v_reservation.declared_size),
    updated_at = now()
  where teacher_id = v_reservation.teacher_id;

  update private.resource_upload_reservations
  set status = 'expired', quota_released_at = now()
  where id = p_reservation_id;
end;
$$;

create function public.complete_resource_deletion(p_job_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_job private.resource_deletion_jobs%rowtype;
begin
  select * into v_job
  from private.resource_deletion_jobs as job
  where job.id = p_job_id
  for update;

  if not found or v_job.status = 'completed' then
    return;
  end if;

  update private.teacher_storage_usage
  set
    committed_bytes = greatest(0, committed_bytes - v_job.file_size),
    updated_at = now()
  where teacher_id = v_job.teacher_id;

  update private.resource_deletion_jobs
  set status = 'completed', completed_at = now(), last_error = null
  where id = p_job_id;
end;
$$;

create function public.record_resource_cleanup_failure(
  p_kind text,
  p_id uuid,
  p_error text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_kind = 'deletion' then
    update private.resource_deletion_jobs
    set
      attempts = attempts + 1,
      last_error = left(coalesce(p_error, 'Storage deletion failed'), 1000),
      available_at = now() + least(interval '6 hours',
        interval '5 minutes' * power(2, least(attempts, 6))::double precision)
    where id = p_id and status = 'pending';
  elsif p_kind = 'reservation' then
    update private.resource_upload_reservations
    set failure_reason = left(coalesce(p_error, 'Storage cleanup failed'), 1000)
    where id = p_id and status in ('pending', 'cancelled');
  else
    raise exception using errcode = '22023', message = 'Unknown cleanup kind';
  end if;
end;
$$;

create function public.reconcile_resource_storage_usage(
  p_teacher_id uuid default null
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer := 0;
  v_teacher_id uuid;
  v_committed_bytes bigint;
  v_reserved_bytes bigint;
begin
  for v_teacher_id in
    select teacher.id
    from public.profiles as teacher
    where (p_teacher_id is null or teacher.id = p_teacher_id)
      and (
        exists (
          select 1 from public.groups where groups.teacher_id = teacher.id
        )
        or exists (
          select 1 from private.teacher_storage_usage as usage
          where usage.teacher_id = teacher.id
        )
      )
  loop
    insert into private.teacher_storage_usage (teacher_id)
    values (v_teacher_id)
    on conflict (teacher_id) do nothing;

    perform 1
    from private.teacher_storage_usage as usage
    where usage.teacher_id = v_teacher_id
    for update;

    select
      coalesce((
        select sum(resource.file_size)
        from public.resources as resource
        where resource.teacher_id = v_teacher_id
          and resource.storage_path is not null
      ), 0) + coalesce((
        select sum(job.file_size)
        from private.resource_deletion_jobs as job
        where job.teacher_id = v_teacher_id and job.status = 'pending'
      ), 0),
      coalesce((
        select sum(reservation.declared_size)
        from private.resource_upload_reservations as reservation
        where reservation.teacher_id = v_teacher_id
          and reservation.status in ('pending', 'cancelled')
          and reservation.quota_released_at is null
      ), 0)
    into v_committed_bytes, v_reserved_bytes;

    update private.teacher_storage_usage
    set
      committed_bytes = v_committed_bytes,
      reserved_bytes = v_reserved_bytes,
      updated_at = now()
    where teacher_id = v_teacher_id;

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke all on function public.create_external_resource(
  uuid, text, text, text, text, uuid
) from public, anon, authenticated;
revoke all on function public.update_resource_metadata(
  uuid, text, text, uuid, text
) from public, anon, authenticated;
grant execute on function public.create_external_resource(
  uuid, text, text, text, text, uuid
) to authenticated;
grant execute on function public.update_resource_metadata(
  uuid, text, text, uuid, text
) to authenticated;

revoke all on function public.reserve_resource_upload(
  uuid, uuid, text, text, text, bigint, text, text, uuid
) from public, anon, authenticated;
revoke all on function public.get_resource_upload_reservation(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.finalize_resource_upload(uuid, uuid, bigint, text)
  from public, anon, authenticated;
revoke all on function public.cancel_resource_upload(
  uuid, uuid, text, boolean
) from public, anon, authenticated;
revoke all on function public.prepare_resource_deletion(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.list_resource_cleanup_work(integer)
  from public, anon, authenticated;
revoke all on function public.complete_resource_reservation_cleanup(uuid)
  from public, anon, authenticated;
revoke all on function public.complete_resource_deletion(uuid)
  from public, anon, authenticated;
revoke all on function public.record_resource_cleanup_failure(text, uuid, text)
  from public, anon, authenticated;
revoke all on function public.reconcile_resource_storage_usage(uuid)
  from public, anon, authenticated;

grant execute on function public.reserve_resource_upload(
  uuid, uuid, text, text, text, bigint, text, text, uuid
) to service_role;
grant execute on function public.get_resource_upload_reservation(uuid, uuid)
  to service_role;
grant execute on function public.finalize_resource_upload(uuid, uuid, bigint, text)
  to service_role;
grant execute on function public.cancel_resource_upload(
  uuid, uuid, text, boolean
) to service_role;
grant execute on function public.prepare_resource_deletion(uuid, uuid)
  to service_role;
grant execute on function public.list_resource_cleanup_work(integer)
  to service_role;
grant execute on function public.complete_resource_reservation_cleanup(uuid)
  to service_role;
grant execute on function public.complete_resource_deletion(uuid)
  to service_role;
grant execute on function public.record_resource_cleanup_failure(text, uuid, text)
  to service_role;
grant execute on function public.reconcile_resource_storage_usage(uuid)
  to service_role;

select cron.schedule(
  'telmizo_phase4_resource_cleanup',
  '*/15 * * * *',
  $cron$
    with cleanup_config as (
      select
        max(decrypted_secret) filter (
          where name = 'telmizo_project_url'
        ) as project_url,
        max(decrypted_secret) filter (
          where name = 'resource_cleanup_secret'
        ) as cleanup_secret
      from vault.decrypted_secrets
    )
    select net.http_post(
      url := cleanup_config.project_url
        || '/functions/v1/resource-storage-cleanup',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-cleanup-secret', cleanup_config.cleanup_secret
      ),
      body := '{}'::jsonb
    )
    from cleanup_config
    where cleanup_config.project_url is not null
      and cleanup_config.cleanup_secret is not null;
  $cron$
);

select cron.schedule(
  'telmizo_phase4_reconcile_resource_usage',
  '40 0 * * *',
  'select public.reconcile_resource_storage_usage(null);'
);

commit;
