-- Cover the Phase 5 foreign keys identified by Supabase Performance Advisor.
create index monthly_payment_plans_created_by_idx
  on public.monthly_payment_plans (created_by);

create index session_payment_items_session_group_idx
  on public.session_payment_items (session_id, group_id);
create index session_payment_items_created_by_idx
  on public.session_payment_items (created_by);

create index one_time_payment_items_created_by_idx
  on public.one_time_payment_items (created_by);

create index payment_obligations_monthly_plan_group_idx
  on public.payment_obligations (monthly_plan_id, group_id);
create index payment_obligations_session_payment_group_idx
  on public.payment_obligations (session_payment_id, group_id);
create index payment_obligations_one_time_item_group_idx
  on public.payment_obligations (one_time_item_id, group_id);
