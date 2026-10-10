-- AFRICA LINK v1.0 Release Candidate — security and data hardening
-- Run after 007_full_platform_integration.sql.

-- Prevent users from changing connection state through a generic UPDATE.
create or replace function public.respond_connection(p_requester_id uuid, p_accept boolean)
returns text language plpgsql security definer set search_path=public as $$
declare result text;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if p_requester_id = auth.uid() then return 'invalid'; end if;
  update public.user_connections
     set status = case when p_accept then 'accepted' else 'declined' end,
         updated_at = now()
   where requester_id = p_requester_id
     and addressee_id = auth.uid()
     and status = 'pending';
  if found then
    result := case when p_accept then 'accepted' else 'declined' end;
    return result;
  end if;
  return 'not_found';
end $$;
grant execute on function public.respond_connection(uuid,boolean) to authenticated;

-- Restrict direct connection updates; state changes go through controlled RPCs.
drop policy if exists "connection update participants" on public.user_connections;

-- Verification submission: a user can submit/re-submit only their own request.
create or replace function public.submit_verification(p_document_type text, p_note text default '')
returns uuid language plpgsql security definer set search_path=public as $$
declare rid uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if coalesce(length(trim(p_document_type)),0) < 2 then raise exception 'Document type is required'; end if;
  select id into rid from public.verification_requests
   where user_id=auth.uid() and status='pending' limit 1;
  if rid is not null then return rid; end if;
  insert into public.verification_requests(user_id,document_type,note,status)
  values(auth.uid(),left(trim(p_document_type),100),left(coalesce(p_note,''),1000),'pending')
  returning id into rid;
  return rid;
end $$;
grant execute on function public.submit_verification(text,text) to authenticated;

-- Minimal role table for server-side moderation/verification operations.
create table if not exists public.platform_roles(
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check(role in ('admin','moderator','verification_reviewer')),
  created_at timestamptz not null default now()
);
alter table public.platform_roles enable row level security;
drop policy if exists "platform roles self read" on public.platform_roles;
create policy "platform roles self read" on public.platform_roles for select using(auth.uid()=user_id);

create or replace function public.is_platform_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.platform_roles where user_id=auth.uid() and role in ('admin','moderator','verification_reviewer'));
$$;
grant execute on function public.is_platform_admin() to authenticated;

-- Controlled verification review. Client users cannot approve themselves.
create or replace function public.review_verification(p_request_id uuid, p_status text, p_note text default '')
returns text language plpgsql security definer set search_path=public as $$
declare target uuid;
begin
  if not public.is_platform_admin() then raise exception 'Not authorized'; end if;
  if p_status not in ('approved','rejected','pending') then raise exception 'Invalid verification status'; end if;
  select user_id into target from public.verification_requests where id=p_request_id;
  if target is null then return 'not_found'; end if;
  update public.verification_requests
     set status=p_status, note=left(coalesce(p_note,''),1000), updated_at=now()
   where id=p_request_id;
  update public.profiles
     set verification_status=case when p_status='approved' then 'verified' when p_status='rejected' then 'rejected' else 'pending' end,
         updated_at=now()
   where id=target;
  perform notify_user(target,'Verification update','Your verification request status is now ' || p_status || '.');
  return p_status;
end $$;
grant execute on function public.review_verification(uuid,text,text) to authenticated;

-- Make read views honor the underlying RLS policies when the database supports security_invoker.
do $$ begin
  execute 'alter view public.feed_posts set (security_invoker = true)';
exception when undefined_object then null; when feature_not_supported then null; end $$;
do $$ begin
  execute 'alter view public.post_comments set (security_invoker = true)';
exception when undefined_object then null; when feature_not_supported then null; end $$;
do $$ begin
  execute 'alter view public.marketplace_feed set (security_invoker = true)';
exception when undefined_object then null; when feature_not_supported then null; end $$;

-- Basic content limits reduce accidental oversized payloads.
alter table public.posts drop constraint if exists posts_body_length;
alter table public.posts add constraint posts_body_length check(length(body) <= 10000);
alter table public.comments drop constraint if exists comments_body_length;
alter table public.comments add constraint comments_body_length check(length(body) <= 5000);
alter table public.messages drop constraint if exists messages_body_length;
alter table public.messages add constraint messages_body_length check(length(body) <= 10000);

create index if not exists idx_platform_roles_role on public.platform_roles(role);
create index if not exists idx_verification_requests_status_created on public.verification_requests(status,created_at desc);
