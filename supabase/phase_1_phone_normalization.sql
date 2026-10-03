begin;

-- Supabase's hosted test-phone path can expose the Auth phone to triggers
-- without a leading plus. Keep profiles canonical instead of weakening the
-- Egyptian E.164 constraint. Real provider values that already include the
-- plus are preserved unchanged.
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

commit;
