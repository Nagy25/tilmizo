create function public.get_my_resource_storage_usage()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_teacher_id uuid := (select auth.uid());
  v_plan_key text;
  v_quota_bytes bigint;
  v_pdf_file_max_bytes bigint;
  v_image_max_bytes bigint;
  v_video_max_bytes bigint;
  v_committed_bytes bigint := 0;
  v_reserved_bytes bigint := 0;
  v_usage_updated_at timestamptz;
  v_used_bytes bigint;
begin
  if v_teacher_id is null then
    raise exception using errcode = '42501',
      message = 'Authentication is required';
  end if;

  select
    selected_plan.plan_key,
    selected_plan.quota_bytes,
    selected_plan.pdf_file_max_bytes,
    selected_plan.image_max_bytes,
    selected_plan.video_max_bytes
  into
    v_plan_key,
    v_quota_bytes,
    v_pdf_file_max_bytes,
    v_image_max_bytes,
    v_video_max_bytes
  from private.resource_plans as selected_plan
  where selected_plan.plan_key = coalesce(
    (
      select assignment.plan_key
      from private.teacher_resource_plans as assignment
      where assignment.teacher_id = v_teacher_id
    ),
    'default'
  );

  if v_quota_bytes is null then
    raise exception using errcode = '55000',
      message = 'Resource storage limits are not configured';
  end if;

  select
    usage.committed_bytes,
    usage.reserved_bytes,
    usage.updated_at
  into
    v_committed_bytes,
    v_reserved_bytes,
    v_usage_updated_at
  from private.teacher_storage_usage as usage
  where usage.teacher_id = v_teacher_id;

  v_committed_bytes := coalesce(v_committed_bytes, 0);
  v_reserved_bytes := coalesce(v_reserved_bytes, 0);
  v_used_bytes := v_committed_bytes + v_reserved_bytes;

  return jsonb_build_object(
    'plan_key', v_plan_key,
    'quota_bytes', v_quota_bytes,
    'committed_bytes', v_committed_bytes,
    'reserved_bytes', v_reserved_bytes,
    'used_bytes', v_used_bytes,
    'remaining_bytes', greatest(0, v_quota_bytes - v_used_bytes),
    'usage_percent', round(
      (v_used_bytes::numeric * 100) / v_quota_bytes::numeric,
      2
    ),
    'pdf_file_max_bytes', v_pdf_file_max_bytes,
    'image_max_bytes', v_image_max_bytes,
    'video_max_bytes', v_video_max_bytes,
    'usage_updated_at', v_usage_updated_at
  );
end;
$$;

revoke all on function public.get_my_resource_storage_usage()
  from public, anon, authenticated;
grant execute on function public.get_my_resource_storage_usage()
  to authenticated;
