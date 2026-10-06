begin;

select plan(14);

select results_eq(
  $$
    select public, file_size_limit
    from storage.buckets
    where id = 'profile-avatars'
  $$,
  $$ values (false, 5242880::bigint) $$,
  'profile-avatars is private with a 5 MB limit'
);

select results_eq(
  $$
    select allowed_mime_types
    from storage.buckets
    where id = 'profile-avatars'
  $$,
  $$ values (array['image/jpeg', 'image/png', 'image/webp']::text[]) $$,
  'profile-avatars accepts only JPEG, PNG, and WebP'
);

select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Profile owners can upload avatars'
      and cmd = 'INSERT'
  ),
  'owners have the avatar insert policy'
);

select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Profile owners can replace avatars'
      and cmd = 'UPDATE'
  ),
  'owners have the avatar update policy'
);

select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Related users can read profile avatars'
      and cmd = 'SELECT'
  ),
  'related users have the avatar read policy'
);

select ok(
  not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname ilike '%avatar%'
      and cmd = 'DELETE'
  ),
  'profile avatars have no delete policy'
);

select has_function(
  'public',
  'set_my_profile_avatar',
  array[]::text[],
  'avatar confirmation RPC exists'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.set_my_profile_avatar()',
    'EXECUTE'
  ),
  'authenticated users can confirm their own avatar'
);

select ok(
  not has_function_privilege(
    'anon',
    'public.set_my_profile_avatar()',
    'EXECUTE'
  ),
  'anonymous users cannot confirm an avatar'
);

select ok(
  not exists (
    select 1
    from pg_proc as avatar_function
    cross join lateral aclexplode(
      coalesce(
        avatar_function.proacl,
        acldefault('f', avatar_function.proowner)
      )
    ) as privilege
    where avatar_function.oid =
      'public.set_my_profile_avatar()'::regprocedure
      and privilege.grantee = 0
      and privilege.privilege_type = 'EXECUTE'
  ),
  'PUBLIC cannot execute the avatar RPC'
);

select ok(
  not has_column_privilege(
    'authenticated',
    'public.profiles',
    'avatar_url',
    'UPDATE'
  ),
  'clients cannot update avatar_url directly'
);

select ok(
  (
    select prosecdef
    from pg_proc
    where oid = 'public.set_my_profile_avatar()'::regprocedure
  ),
  'avatar RPC is security definer'
);

select ok(
  (
    select proconfig @> array['search_path=""']::text[]
    from pg_proc
    where oid = 'public.set_my_profile_avatar()'::regprocedure
  ),
  'avatar RPC pins an empty search path'
);

select is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'Profile owners can upload avatars',
        'Profile owners can replace avatars',
        'Related users can read profile avatars'
      )
  ),
  3,
  'exactly three avatar policies are installed'
);

select * from finish();
rollback;
