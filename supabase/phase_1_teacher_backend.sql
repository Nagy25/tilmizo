begin;

create schema if not exists private;

revoke all on schema private from public;
revoke all on schema private from anon;
revoke all on schema private from authenticated;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  phone text not null unique,
  teaching_subject text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_full_name_not_blank check (
    full_name is null or btrim(full_name) <> ''
  ),
  constraint profiles_phone_egyptian_mobile check (
    phone ~ '^\+201[0125][0-9]{8}$'
  ),
  constraint profiles_teaching_subject_not_blank check (
    teaching_subject is null or btrim(teaching_subject) <> ''
  )
);

create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  subject text,
  grade text,
  invite_code text unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint groups_name_not_blank check (btrim(name) <> ''),
  constraint groups_invite_code_not_blank check (
    invite_code is null or btrim(invite_code) <> ''
  )
);

create index if not exists groups_teacher_id_is_active_idx
  on public.groups (teacher_id, is_active);

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op <> 'INSERT'
    or tg_table_schema <> 'auth'
    or tg_table_name <> 'users'
  then
    raise exception 'private.handle_new_user may only run from auth.users inserts';
  end if;

  insert into public.profiles (id, full_name, phone, avatar_url)
  values (
    new.id,
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
      nullif(
        btrim(
          concat_ws(
            ' ',
            new.raw_user_meta_data ->> 'given_name',
            new.raw_user_meta_data ->> 'family_name'
          )
        ),
        ''
      )
    ),
    case
      when new.phone ~ '^201[0125][0-9]{8}$' then '+' || new.phone
      else new.phone
    end,
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'avatar_url'), ''),
      nullif(btrim(new.raw_user_meta_data ->> 'picture'), '')
    )
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create or replace function private.sync_profile_phone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op <> 'UPDATE'
    or tg_table_schema <> 'auth'
    or tg_table_name <> 'users'
  then
    raise exception 'private.sync_profile_phone may only run from auth.users updates';
  end if;

  update public.profiles
  set phone = case
    when new.phone ~ '^201[0125][0-9]{8}$' then '+' || new.phone
    else new.phone
  end
  where id = new.id;

  return new;
end;
$$;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function private.handle_new_user() from public;
revoke all on function private.handle_new_user() from anon;
revoke all on function private.handle_new_user() from authenticated;
revoke all on function private.sync_profile_phone() from public;
revoke all on function private.sync_profile_phone() from anon;
revoke all on function private.sync_profile_phone() from authenticated;
revoke all on function private.set_updated_at() from public;
revoke all on function private.set_updated_at() from anon;
revoke all on function private.set_updated_at() from authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

drop trigger if exists on_auth_user_phone_updated on auth.users;
create trigger on_auth_user_phone_updated
  after update of phone on auth.users
  for each row
  when (old.phone is distinct from new.phone)
  execute function private.sync_profile_phone();

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function private.set_updated_at();

drop trigger if exists set_groups_updated_at on public.groups;
create trigger set_groups_updated_at
  before update on public.groups
  for each row execute function private.set_updated_at();

alter table public.profiles enable row level security;
alter table public.groups enable row level security;

revoke all on table public.profiles from anon;
revoke all on table public.profiles from authenticated;
revoke all on table public.groups from anon;
revoke all on table public.groups from authenticated;

grant select on table public.profiles to authenticated;
grant update (full_name, teaching_subject, avatar_url)
  on table public.profiles to authenticated;

grant select, delete on table public.groups to authenticated;
grant insert (teacher_id, name, subject, grade, invite_code, is_active)
  on table public.groups to authenticated;
grant update (name, subject, grade, invite_code, is_active)
  on table public.groups to authenticated;

grant all on table public.profiles to service_role;
grant all on table public.groups to service_role;

drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
on public.profiles
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = id
);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
on public.profiles
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = id
);

drop policy if exists "Teachers can create their own groups" on public.groups;
create policy "Teachers can create their own groups"
on public.groups
for insert
to authenticated
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = teacher_id
);

drop policy if exists "Teachers can read their own groups" on public.groups;
create policy "Teachers can read their own groups"
on public.groups
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = teacher_id
);

drop policy if exists "Teachers can update their own groups" on public.groups;
create policy "Teachers can update their own groups"
on public.groups
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = teacher_id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = teacher_id
);

drop policy if exists "Teachers can delete their own groups" on public.groups;
create policy "Teachers can delete their own groups"
on public.groups
for delete
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = teacher_id
);

commit;
