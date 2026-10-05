-- Phase 2 membership RLS already restricts reads to owned groups (or the
-- student's own approved session), but the live table lacked its SELECT grant.
grant select on table public.group_memberships to authenticated;
