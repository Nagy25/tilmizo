begin;

create or replace function private.generate_phase6_reminders() returns integer
language plpgsql security definer set search_path = '' as $$
declare v_today date := (now() at time zone 'Africa/Cairo')::date;
  v_count integer := 0; v_rows integer;
begin
  insert into public.user_notifications(user_id,group_id,event_type,target_id,title,dedupe_key)
  select m.student_id,h.group_id,'homework_due_soon',h.id,'اقترب موعد تسليم الواجب',
    'homework-due:'||h.id||':'||h.due_date
  from public.homework h join public.groups g on g.id=h.group_id
  join public.class_sessions s on s.id=h.session_id and s.status<>'cancelled'
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

revoke all on function private.generate_phase6_reminders() from public,anon,authenticated;

commit;
