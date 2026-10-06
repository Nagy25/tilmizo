-- Archiving is a read-only boundary for Phase 3 data. Keep the existing
-- SELECT policies unchanged so teachers and approved students retain history.
create or replace function private.owns_active_group(p_group_id uuid)
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
        and owned_group.is_active
    );
$$;

revoke all on function private.owns_active_group(uuid)
  from public, anon, authenticated;
grant execute on function private.owns_active_group(uuid) to authenticated;

alter policy "Teachers can create owned group schedules"
on public.group_schedule_entries
with check (private.owns_active_group(group_id));

alter policy "Teachers can update owned group schedules"
on public.group_schedule_entries
using (private.owns_active_group(group_id))
with check (private.owns_active_group(group_id));

alter policy "Teachers can delete owned group schedules"
on public.group_schedule_entries
using (private.owns_active_group(group_id));

alter policy "Teachers can update owned class sessions"
on public.class_sessions
using (private.owns_active_group(group_id))
with check (private.owns_active_group(group_id));

-- This security-definer RPC bypasses attendance RLS, so it must enforce the
-- archive boundary itself. Existing marks remain readable but unchangeable.
create or replace function public.set_session_attendance(
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

  if v_group_id is null or not private.owns_active_group(v_group_id) then
    raise exception using errcode = '42501',
      message = 'An active owned class session is required';
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
