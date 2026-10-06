begin;

select plan(34);

select has_table('public', 'resources', 'resources table exists');
select has_table('private', 'resource_plans', 'resource plans table exists');
select has_table(
  'private', 'teacher_resource_plans', 'teacher plan assignments table exists'
);
select has_table(
  'private', 'teacher_storage_usage', 'teacher storage ledger exists'
);
select has_table(
  'private', 'resource_upload_reservations', 'upload reservations table exists'
);
select has_table(
  'private', 'resource_deletion_jobs', 'deletion outbox table exists'
);

select col_is_pk('public', 'resources', 'id', 'resource id is the primary key');
select col_not_null('public', 'resources', 'group_id', 'group is required');
select col_not_null('public', 'resources', 'teacher_id', 'teacher is required');
select col_not_null('public', 'resources', 'type', 'resource type is required');
select col_not_null('public', 'resources', 'title', 'resource title is required');

select ok(
  (
    select relrowsecurity
    from pg_class
    where oid = 'public.resources'::regclass
  ),
  'resources has RLS enabled'
);
select ok(
  has_table_privilege('authenticated', 'public.resources', 'SELECT'),
  'authenticated users have explicit resource read access'
);
select ok(
  not has_table_privilege('authenticated', 'public.resources', 'INSERT'),
  'authenticated users cannot insert resources directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.resources', 'UPDATE'),
  'authenticated users cannot update resources directly'
);
select ok(
  not has_table_privilege('authenticated', 'public.resources', 'DELETE'),
  'authenticated users cannot delete resources directly'
);
select ok(
  not has_table_privilege('anon', 'public.resources', 'SELECT'),
  'anonymous users cannot read resources'
);

select policies_are(
  'public',
  'resources',
  array['Teachers and approved students can read resources'],
  'resources exposes only the intended read policy'
);
select ok(
  exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Authenticated group resource downloads'
      and cmd = 'SELECT'
  ),
  'private bucket downloads are protected by a Storage SELECT policy'
);

select results_eq(
  $$
    select public, file_size_limit
    from storage.buckets
    where id = 'group-resources'
  $$,
  $$ values (false, 52428800::bigint) $$,
  'group-resources is private with a 50 MB bucket limit'
);

select results_eq(
  $$
    select quota_bytes, pdf_file_max_bytes, image_max_bytes, video_max_bytes
    from private.resource_plans
    where plan_key = 'default'
  $$,
  $$ values (
    1073741824::bigint,
    26214400::bigint,
    10485760::bigint,
    52428800::bigint
  ) $$,
  'default configurable resource limits are seeded'
);

select has_function(
  'public',
  'create_external_resource',
  array['uuid', 'text', 'text', 'text', 'text', 'uuid'],
  'external resource creation RPC exists'
);
select has_function(
  'public',
  'update_resource_metadata',
  array['uuid', 'text', 'text', 'uuid', 'text'],
  'resource metadata update RPC exists'
);
select has_function(
  'public',
  'reserve_resource_upload',
  array['uuid', 'uuid', 'text', 'text', 'text', 'bigint', 'text', 'text', 'uuid'],
  'upload reservation RPC exists'
);
select has_function(
  'public',
  'finalize_resource_upload',
  array['uuid', 'uuid', 'bigint', 'text'],
  'upload finalization RPC exists'
);
select has_function(
  'public',
  'prepare_resource_deletion',
  array['uuid', 'uuid'],
  'resource deletion preparation RPC exists'
);
select has_function(
  'public',
  'get_my_resource_storage_usage',
  array[]::text[],
  'teacher resource storage usage RPC exists'
);

select ok(
  has_function_privilege(
    'authenticated',
    'public.create_external_resource(uuid,text,text,text,text,uuid)',
    'EXECUTE'
  ),
  'authenticated teachers can call external resource creation'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.get_my_resource_storage_usage()',
    'EXECUTE'
  ),
  'authenticated teachers can read their own resource storage usage'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.get_my_resource_storage_usage()',
    'EXECUTE'
  ),
  'anonymous users cannot read teacher resource storage usage'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.reserve_resource_upload(uuid,uuid,text,text,text,bigint,text,text,uuid)',
    'EXECUTE'
  ),
  'clients cannot bypass the upload Edge Function'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.reserve_resource_upload(uuid,uuid,text,text,text,bigint,text,text,uuid)',
    'EXECUTE'
  ),
  'the upload Edge Function can reserve quota through service role'
);
select ok(
  exists (
    select 1 from cron.job
    where jobname = 'telmizo_phase4_resource_cleanup'
      and schedule = '*/15 * * * *'
  ),
  'resource object cleanup is scheduled every 15 minutes'
);
select ok(
  exists (
    select 1 from cron.job
    where jobname = 'telmizo_phase4_reconcile_resource_usage'
      and schedule = '40 0 * * *'
  ),
  'resource quota reconciliation is scheduled daily'
);

select * from finish();
rollback;
