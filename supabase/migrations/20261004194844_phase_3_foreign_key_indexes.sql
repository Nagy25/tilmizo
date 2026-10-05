begin;

-- Cover both columns of the composite foreign keys. The occurrence unique
-- index uses a different second column, and attendance's unique index does
-- not include group_id.
create index class_sessions_schedule_group_idx
  on public.class_sessions (schedule_entry_id, group_id);

create index session_attendance_session_group_idx
  on public.session_attendance (session_id, group_id);

commit;
