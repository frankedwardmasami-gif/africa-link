-- AFRICA LINK v1.1 Admin, Privacy & Deployment Layer
-- Run after 009_production_readiness.sql.

create table if not exists public.user_preferences(
  user_id uuid primary key references auth.users(id) on delete cascade,
  profile_visibility text not null default 'public' check(profile_visibility in ('public','connections','private')),
  show_online_status boolean not null default true,
  allow_connection_requests boolean not null default true,
  allow_direct_messages text not null default 'connections' check(allow_direct_messages in ('everyone','connections','nobody')),
  language text not null default 'en',
  marketing_notifications boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table public.user_preferences enable row level security;
drop policy if exists "preferences owner read" on public.user_preferences;
drop policy if exists "preferences owner insert" on public.user_preferences;
drop policy if exists "preferences owner update" on public.user_preferences;
create policy "preferences owner read" on public.user_preferences for select using(auth.uid()=user_id);
create policy "preferences owner insert" on public.user_preferences for insert with check(auth.uid()=user_id);
create policy "preferences owner update" on public.user_preferences for update using(auth.uid()=user_id) with check(auth.uid()=user_id);

create table if not exists public.account_deletion_requests(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null default '',
  status text not null default 'requested' check(status in ('requested','cancelled','processed')),
  requested_at timestamptz not null default now(),
  processed_at timestamptz
);
alter table public.account_deletion_requests enable row level security;
drop policy if exists "deletion own read" on public.account_deletion_requests;
create policy "deletion own read" on public.account_deletion_requests for select using(auth.uid()=user_id);

create table if not exists public.audit_logs(
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
alter table public.audit_logs enable row level security;

create or replace function public.save_user_preferences(
  p_profile_visibility text default 'public',
  p_show_online_status boolean default true,
  p_allow_connection_requests boolean default true,
  p_allow_direct_messages text default 'connections',
  p_language text default 'en',
  p_marketing_notifications boolean default false
) returns void language plpgsql security definer set search_path=public as $$
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if p_profile_visibility not in ('public','connections','private') then raise exception 'Invalid visibility'; end if;
  if p_allow_direct_messages not in ('everyone','connections','nobody') then raise exception 'Invalid message setting'; end if;
  insert into public.user_preferences(user_id,profile_visibility,show_online_status,allow_connection_requests,allow_direct_messages,language,marketing_notifications,updated_at)
  values(auth.uid(),p_profile_visibility,p_show_online_status,p_allow_connection_requests,p_allow_direct_messages,left(coalesce(p_language,'en'),10),p_marketing_notifications,now())
  on conflict(user_id) do update set
    profile_visibility=excluded.profile_visibility,
    show_online_status=excluded.show_online_status,
    allow_connection_requests=excluded.allow_connection_requests,
    allow_direct_messages=excluded.allow_direct_messages,
    language=excluded.language,
    marketing_notifications=excluded.marketing_notifications,
    updated_at=now();
end $$;
grant execute on function public.save_user_preferences(text,boolean,boolean,text,text,boolean) to authenticated;

create or replace function public.request_account_deletion(p_reason text default '') returns uuid language plpgsql security definer set search_path=public as $$
declare rid uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  select id into rid from public.account_deletion_requests where user_id=auth.uid() and status='requested' order by requested_at desc limit 1;
  if rid is not null then return rid; end if;
  insert into public.account_deletion_requests(user_id,reason) values(auth.uid(),left(coalesce(p_reason,''),1000)) returning id into rid;
  return rid;
end $$;
grant execute on function public.request_account_deletion(text) to authenticated;

create or replace function public.cancel_account_deletion() returns text language plpgsql security definer set search_path=public as $$
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  update public.account_deletion_requests set status='cancelled' where user_id=auth.uid() and status='requested';
  return 'cancelled';
end $$;
grant execute on function public.cancel_account_deletion() to authenticated;

create or replace function public.admin_resolve_report(p_report_id uuid, p_status text, p_note text default '') returns text language plpgsql security definer set search_path=public as $$
declare r text;
begin
  if not public.is_platform_admin() then raise exception 'Not authorized'; end if;
  if p_status not in ('reviewing','resolved','dismissed') then raise exception 'Invalid report status'; end if;
  update public.safety_reports set status=p_status, admin_note=left(coalesce(p_note,''),1000), updated_at=now() where id=p_report_id returning status into r;
  if r is null then return 'not_found'; end if;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata) values(auth.uid(),'resolve_report','safety_report',p_report_id::text,jsonb_build_object('status',p_status));
  return r;
end $$;
grant execute on function public.admin_resolve_report(uuid,text,text) to authenticated;

create or replace function public.admin_review_deletion(p_request_id uuid, p_process boolean) returns text language plpgsql security definer set search_path=public as $$
declare r text;
begin
  if not public.is_platform_admin() then raise exception 'Not authorized'; end if;
  update public.account_deletion_requests set status=case when p_process then 'processed' else 'cancelled' end, processed_at=now() where id=p_request_id returning status into r;
  if r is null then return 'not_found'; end if;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata) values(auth.uid(),'review_deletion','account_deletion_request',p_request_id::text,jsonb_build_object('processed',p_process));
  return r;
end $$;
grant execute on function public.admin_review_deletion(uuid,boolean) to authenticated;

create index if not exists idx_user_preferences_language on public.user_preferences(language);
create index if not exists idx_deletion_requests_status on public.account_deletion_requests(status,requested_at desc);
create index if not exists idx_audit_logs_created on public.audit_logs(created_at desc);
create index if not exists idx_audit_logs_actor on public.audit_logs(actor_id,created_at desc);
