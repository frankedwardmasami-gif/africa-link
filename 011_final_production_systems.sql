-- AFRICA LINK v1.2 Final Production Systems
-- Run after 010_admin_privacy_deployment.sql.

create table if not exists public.media_assets(
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  bucket text not null check(bucket in ('avatars','media','documents')),
  object_path text not null,
  mime_type text not null default 'application/octet-stream',
  size_bytes bigint not null default 0 check(size_bytes >= 0),
  status text not null default 'active' check(status in ('active','deleted','quarantined')),
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique(bucket, object_path)
);
alter table public.media_assets enable row level security;
drop policy if exists "media owner read" on public.media_assets;
drop policy if exists "media owner insert" on public.media_assets;
drop policy if exists "media owner update" on public.media_assets;
create policy "media owner read" on public.media_assets for select using(auth.uid()=owner_id);
create policy "media owner insert" on public.media_assets for insert with check(auth.uid()=owner_id);
create policy "media owner update" on public.media_assets for update using(auth.uid()=owner_id) with check(auth.uid()=owner_id);

create table if not exists public.push_devices(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check(platform in ('android','ios','web')),
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id, token)
);
alter table public.push_devices enable row level security;
drop policy if exists "push devices owner" on public.push_devices;
create policy "push devices owner" on public.push_devices for all using(auth.uid()=user_id) with check(auth.uid()=user_id);

create table if not exists public.notification_preferences(
  user_id uuid primary key references auth.users(id) on delete cascade,
  messages boolean not null default true,
  connections boolean not null default true,
  events boolean not null default true,
  opportunities boolean not null default true,
  education boolean not null default true,
  marketplace boolean not null default true,
  projects boolean not null default true,
  system boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.notification_preferences enable row level security;
drop policy if exists "notification preferences owner" on public.notification_preferences;
create policy "notification preferences owner" on public.notification_preferences for all using(auth.uid()=user_id) with check(auth.uid()=user_id);

create table if not exists public.content_reports(
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  content_type text not null check(content_type in ('post','comment','message','community_post','profile','business','event','project')),
  content_id text not null,
  reason text not null,
  details text not null default '',
  status text not null default 'open' check(status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.content_reports enable row level security;
drop policy if exists "content reports own read" on public.content_reports;
drop policy if exists "content reports own insert" on public.content_reports;
create policy "content reports own read" on public.content_reports for select using(auth.uid()=reporter_id);
create policy "content reports own insert" on public.content_reports for insert with check(auth.uid()=reporter_id);

create index if not exists idx_media_owner_created on public.media_assets(owner_id,created_at desc);
create index if not exists idx_push_devices_user_enabled on public.push_devices(user_id,enabled);
create index if not exists idx_content_reports_status_created on public.content_reports(status,created_at desc);

create or replace function public.register_push_device(p_token text,p_platform text) returns uuid
language plpgsql security definer set search_path=public as $$
declare rid uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if length(trim(coalesce(p_token,''))) < 10 then raise exception 'Invalid push token'; end if;
  if p_platform not in ('android','ios','web') then raise exception 'Invalid platform'; end if;
  insert into public.push_devices(user_id,token,platform,enabled,last_seen_at)
  values(auth.uid(),trim(p_token),p_platform,true,now())
  on conflict(user_id,token) do update set enabled=true,platform=excluded.platform,last_seen_at=now()
  returning id into rid;
  return rid;
end $$;
grant execute on function public.register_push_device(text,text) to authenticated;

create or replace function public.save_notification_preferences(
 p_messages boolean default true,p_connections boolean default true,p_events boolean default true,
 p_opportunities boolean default true,p_education boolean default true,p_marketplace boolean default true,
 p_projects boolean default true,p_system boolean default true
) returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 insert into public.notification_preferences(user_id,messages,connections,events,opportunities,education,marketplace,projects,system,updated_at)
 values(auth.uid(),p_messages,p_connections,p_events,p_opportunities,p_education,p_marketplace,p_projects,p_system,now())
 on conflict(user_id) do update set messages=excluded.messages,connections=excluded.connections,events=excluded.events,
 opportunities=excluded.opportunities,education=excluded.education,marketplace=excluded.marketplace,projects=excluded.projects,
 system=excluded.system,updated_at=now();
end $$;
grant execute on function public.save_notification_preferences(boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean) to authenticated;

create or replace function public.create_content_report(p_content_type text,p_content_id text,p_reason text,p_details text default '') returns uuid
language plpgsql security definer set search_path=public as $$
declare rid uuid;
begin
 if auth.uid() is null then raise exception 'Not authenticated'; end if;
 if p_content_type not in ('post','comment','message','community_post','profile','business','event','project') then raise exception 'Invalid content type'; end if;
 if length(trim(coalesce(p_reason,''))) < 3 then raise exception 'Reason required'; end if;
 insert into public.content_reports(reporter_id,content_type,content_id,reason,details)
 values(auth.uid(),p_content_type,left(p_content_id,200),left(trim(p_reason),120),left(coalesce(p_details,''),2000)) returning id into rid;
 return rid;
end $$;
grant execute on function public.create_content_report(text,text,text,text) to authenticated;

-- Storage buckets are intentionally private. Production deployments should create these buckets
-- through Supabase Dashboard/CLI with matching limits and virus/media scanning as required.
