begin;

do $$
begin
  if to_regclass('public.profiles') is null then
    raise exception 'Profile avatars require public.profiles';
  end if;
end;
$$;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'profile-avatars',
  'profile-avatars',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

revoke update (avatar_url) on table public.profiles from authenticated;

drop policy if exists "Profile owners can upload avatars"
  on storage.objects;
create policy "Profile owners can upload avatars"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-avatars'
  and (select auth.uid()) is not null
  and name = (select auth.uid())::text || '/avatar'
);

drop policy if exists "Profile owners can replace avatars"
  on storage.objects;
create policy "Profile owners can replace avatars"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-avatars'
  and (select auth.uid()) is not null
  and name = (select auth.uid())::text || '/avatar'
)
with check (
  bucket_id = 'profile-avatars'
  and (select auth.uid()) is not null
  and name = (select auth.uid())::text || '/avatar'
);

drop policy if exists "Related users can read profile avatars"
  on storage.objects;
create policy "Related users can read profile avatars"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'profile-avatars'
  and (
    name = (select auth.uid())::text || '/avatar'
    or exists (
      select 1
      from public.profiles as visible_profile
      where visible_profile.avatar_url = storage.objects.name
        and visible_profile.id::text || '/avatar' = storage.objects.name
    )
  )
);

create or replace function public.set_my_profile_avatar()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_avatar_path text;
  v_updated_at timestamptz;
begin
  if v_user_id is null then
    raise exception using errcode = '42501',
      message = 'Authentication is required';
  end if;

  v_avatar_path := v_user_id::text || '/avatar';

  if not exists (
    select 1
    from storage.objects as avatar_object
    where avatar_object.bucket_id = 'profile-avatars'
      and avatar_object.name = v_avatar_path
      and avatar_object.owner_id = v_user_id::text
  ) then
    raise exception using errcode = '22023',
      message = 'Upload your profile avatar before confirming it';
  end if;

  update public.profiles as caller_profile
  set avatar_url = v_avatar_path
  where caller_profile.id = v_user_id
  returning caller_profile.updated_at into v_updated_at;

  if not found then
    raise exception using errcode = 'P0002',
      message = 'The authenticated profile was not found';
  end if;

  return jsonb_build_object(
    'avatar_path', v_avatar_path,
    'updated_at', v_updated_at
  );
end;
$$;

revoke all on function public.set_my_profile_avatar()
  from public, anon, authenticated;
grant execute on function public.set_my_profile_avatar()
  to authenticated;

commit;
