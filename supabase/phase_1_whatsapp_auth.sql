begin;

do $$
begin
  if exists (
    select 1
    from auth.users
    where phone is null
       or phone !~ '^\+201[0125][0-9]{8}$'
  ) then
    raise exception using
      message = 'WhatsApp migration requires every auth user to have a valid Egyptian mobile number in E.164 format';
  end if;
end;
$$;

alter table public.profiles
  add column if not exists teaching_subject text;

update public.profiles as profile
set phone = auth_user.phone
from auth.users as auth_user
where auth_user.id = profile.id
  and profile.phone is distinct from auth_user.phone;

alter table public.profiles
  alter column phone set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_phone_key'
  ) then
    alter table public.profiles
      add constraint profiles_phone_key unique (phone);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_full_name_not_blank'
  ) then
    alter table public.profiles
      add constraint profiles_full_name_not_blank check (
        full_name is null or btrim(full_name) <> ''
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_phone_egyptian_mobile'
  ) then
    alter table public.profiles
      add constraint profiles_phone_egyptian_mobile check (
        phone ~ '^\+201[0125][0-9]{8}$'
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_teaching_subject_not_blank'
  ) then
    alter table public.profiles
      add constraint profiles_teaching_subject_not_blank check (
        teaching_subject is null or btrim(teaching_subject) <> ''
      );
  end if;
end;
$$;

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

revoke all on function private.handle_new_user() from public;
revoke all on function private.handle_new_user() from anon;
revoke all on function private.handle_new_user() from authenticated;
revoke all on function private.sync_profile_phone() from public;
revoke all on function private.sync_profile_phone() from anon;
revoke all on function private.sync_profile_phone() from authenticated;

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

revoke all on table public.profiles from anon;
revoke all on table public.profiles from authenticated;

grant select on table public.profiles to authenticated;
grant update (full_name, teaching_subject, avatar_url)
  on table public.profiles to authenticated;
grant all on table public.profiles to service_role;

commit;
