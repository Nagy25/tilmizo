begin;

drop policy if exists "Approved students and teachers can read memberships"
  on public.group_memberships;
drop policy if exists "Students and teachers can read relevant memberships"
  on public.group_memberships;
create policy "Students and teachers can read relevant memberships"
on public.group_memberships
for select
to authenticated
using (
  private.owns_group(group_id)
  or student_id = (select auth.uid())
);

create or replace function public.get_my_group_access_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := (select auth.uid());
  v_session_id_text text := nullif((select auth.jwt()) ->> 'session_id', '');
  v_session_id uuid;
  v_result jsonb;
begin
  if v_student_id is null or v_session_id_text is null then
    raise exception using errcode = '42501',
      message = 'Authentication with an active session is required';
  end if;

  begin
    v_session_id := v_session_id_text::uuid;
  exception when invalid_text_representation then
    raise exception using errcode = '42501',
      message = 'The authenticated session is invalid';
  end;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'group_id', overview.group_id,
        'group_name', overview.group_name,
        'subject', overview.subject,
        'grade', overview.grade,
        'teacher_id', overview.teacher_id,
        'teacher_name', overview.teacher_name,
        'membership_id', overview.membership_id,
        'membership_status', overview.membership_status,
        'approved_device_name', overview.approved_device_name,
        'latest_request_id', overview.latest_request_id,
        'latest_request_status', overview.latest_request_status,
        'latest_request_type', overview.latest_request_type,
        'latest_request_is_current_session',
          overview.latest_request_session_id = v_session_id,
        'is_current_session_approved',
          overview.membership_status = 'active'
          and overview.approved_session_id = v_session_id,
        'can_request_device_replacement',
          overview.membership_status = 'active'
          and overview.approved_session_id is distinct from v_session_id
          and not (
            overview.latest_request_status = 'pending'
            and overview.latest_request_type = 'device_replacement'
            and overview.latest_request_session_id = v_session_id
          ),
        'access_state', case
          when overview.membership_status in ('suspended', 'removed')
            then overview.membership_status
          when overview.latest_request_status = 'pending'
            and overview.latest_request_session_id = v_session_id
            and overview.latest_request_type = 'device_replacement'
            then 'device_replacement_pending'
          when overview.latest_request_status = 'pending'
            and overview.latest_request_session_id = v_session_id
            then 'join_pending'
          when overview.membership_status = 'active'
            and overview.approved_session_id = v_session_id
            then 'approved'
          when overview.membership_status = 'active'
            then 'different_device'
          when overview.latest_request_status = 'rejected'
            and overview.latest_request_session_id = v_session_id
            then 'rejected'
          else 'none'
        end,
        'updated_at', greatest(
          coalesce(overview.membership_updated_at, '-infinity'::timestamptz),
          coalesce(overview.request_updated_at, '-infinity'::timestamptz),
          overview.group_updated_at
        )
      )
      order by greatest(
        coalesce(overview.membership_updated_at, '-infinity'::timestamptz),
        coalesce(overview.request_updated_at, '-infinity'::timestamptz),
        overview.group_updated_at
      ) desc
    ),
    '[]'::jsonb
  )
  into v_result
  from (
    select
      joined_group.id as group_id,
      joined_group.name as group_name,
      joined_group.subject,
      joined_group.grade,
      joined_group.teacher_id,
      teacher_profile.full_name as teacher_name,
      joined_group.updated_at as group_updated_at,
      membership.id as membership_id,
      membership.status as membership_status,
      membership.approved_session_id,
      membership.updated_at as membership_updated_at,
      approved_device.device_name as approved_device_name,
      latest_request.id as latest_request_id,
      latest_request.status as latest_request_status,
      latest_request.request_type as latest_request_type,
      latest_request.session_id as latest_request_session_id,
      latest_request.updated_at as request_updated_at
    from (
      select relevant.group_id
      from (
        select existing_membership.group_id
        from public.group_memberships as existing_membership
        where existing_membership.student_id = v_student_id
        union
        select existing_request.group_id
        from public.group_join_requests as existing_request
        where existing_request.student_id = v_student_id
      ) as relevant
    ) as relevant_group
    join public.groups as joined_group
      on joined_group.id = relevant_group.group_id
    left join public.profiles as teacher_profile
      on teacher_profile.id = joined_group.teacher_id
    left join public.group_memberships as membership
      on membership.group_id = joined_group.id
      and membership.student_id = v_student_id
    left join public.student_devices as approved_device
      on approved_device.id = membership.approved_device_id
    left join lateral (
      select request.*
      from public.group_join_requests as request
      where request.group_id = joined_group.id
        and request.student_id = v_student_id
      order by (request.status = 'pending') desc,
        request.created_at desc,
        request.id desc
      limit 1
    ) as latest_request on true
  ) as overview;

  return v_result;
end;
$$;

create or replace function public.request_group_device_replacement(
  p_membership_id uuid,
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
  v_membership public.group_memberships%rowtype;
  v_device_id uuid;
  v_request_id uuid;
  v_installation_hash text;
begin
  if v_student_id is null or v_session_id_text is null then
    raise exception using errcode = '42501',
      message = 'Authentication with an active session is required';
  end if;

  begin
    v_session_id := v_session_id_text::uuid;
  exception when invalid_text_representation then
    raise exception using errcode = '42501',
      message = 'The authenticated session is invalid';
  end;

  if p_membership_id is null then
    raise exception using errcode = '22023', message = 'A valid membership is required';
  end if;
  if p_installation_id is null
    or char_length(p_installation_id) < 16
    or char_length(p_installation_id) > 200 then
    raise exception using errcode = '22023', message = 'A valid installation identifier is required';
  end if;
  if p_device_name is null
    or btrim(p_device_name) = ''
    or char_length(btrim(p_device_name)) > 120 then
    raise exception using errcode = '22023', message = 'A valid device name is required';
  end if;
  if lower(btrim(coalesce(p_platform, ''))) not in ('android', 'ios') then
    raise exception using errcode = '22023', message = 'The device platform is not supported';
  end if;
  if p_app_version is not null
    and (btrim(p_app_version) = '' or char_length(btrim(p_app_version)) > 50) then
    raise exception using errcode = '22023', message = 'The app version is invalid';
  end if;

  select membership.*
  into v_membership
  from public.group_memberships as membership
  join public.groups as joined_group on joined_group.id = membership.group_id
  where membership.id = p_membership_id
    and membership.student_id = v_student_id
    and membership.status = 'active'
    and joined_group.is_active
  for update of membership;

  if not found then
    raise exception using errcode = '42501',
      message = 'The membership is unavailable for device replacement';
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
  ) values (
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

  if v_membership.approved_device_id = v_device_id then
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

  select request.id
  into v_request_id
  from public.group_join_requests as request
  where request.group_id = v_membership.group_id
    and request.student_id = v_student_id
    and request.status = 'pending'
  for update;

  if v_request_id is null then
    insert into public.group_join_requests (
      group_id,
      student_id,
      device_id,
      session_id,
      request_type,
      created_at
    ) values (
      v_membership.group_id,
      v_student_id,
      v_device_id,
      v_session_id,
      'device_replacement',
      clock_timestamp()
    )
    returning id into v_request_id;
  else
    update public.group_join_requests
    set device_id = v_device_id,
        session_id = v_session_id,
        request_type = 'device_replacement',
        created_at = clock_timestamp()
    where id = v_request_id;
  end if;

  return jsonb_build_object(
    'status', 'pending',
    'request_type', 'device_replacement',
    'request_id', v_request_id,
    'membership_id', v_membership.id
  );
end;
$$;

revoke all on function public.get_my_group_access_overview() from public;
revoke all on function public.get_my_group_access_overview() from anon;
grant execute on function public.get_my_group_access_overview() to authenticated;

revoke all on function public.request_group_device_replacement(uuid, text, text, text, text) from public;
revoke all on function public.request_group_device_replacement(uuid, text, text, text, text) from anon;
grant execute on function public.request_group_device_replacement(uuid, text, text, text, text) to authenticated;

-- RLS is the row boundary; these grants are the column boundary. Never expose
-- installation hashes or Supabase session UUIDs through direct Data API reads.
revoke select on table public.student_devices from authenticated;
revoke select on table public.group_join_requests from authenticated;
revoke select on table public.group_memberships from authenticated;

grant select (
  id, student_id, device_name, platform, app_version,
  created_at, last_seen_at, updated_at
) on public.student_devices to authenticated;

grant select (
  id, group_id, student_id, device_id, request_type, status,
  created_at, updated_at, decided_at, decided_by
) on public.group_join_requests to authenticated;

grant select (
  id, group_id, student_id, approved_device_id, status,
  joined_at, updated_at
) on public.group_memberships to authenticated;

commit;
