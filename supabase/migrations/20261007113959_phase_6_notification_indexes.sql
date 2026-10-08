begin;

create index homework_group_teacher_fk_idx on public.homework(group_id, teacher_id);
create index homework_session_group_fk_idx on public.homework(session_id, group_id);
create index homework_resources_homework_group_fk_idx on public.homework_resources(homework_id, group_id);
create index announcements_group_teacher_fk_idx on public.announcements(group_id, teacher_id);
create index user_notifications_group_fk_idx on public.user_notifications(group_id) where group_id is not null;
create index notification_deliveries_device_fk_idx on private.notification_deliveries(device_id);

commit;
