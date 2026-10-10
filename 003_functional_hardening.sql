-- AFRICA LINK v0.5.1 functional hardening
-- Run after 001_core.sql and 002_remaining_modules.sql.

create table if not exists public.community_conversations(
  community_id uuid primary key references public.communities(id) on delete cascade,
  conversation_id uuid unique not null references public.conversations(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.verification_requests(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null,
  status text not null default 'pending' check(status in ('pending','approved','rejected')),
  note text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.safety_reports(
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid references public.profiles(id) on delete cascade,
  content_type text,
  content_id uuid,
  reason text not null,
  details text default '',
  status text not null default 'open' check(status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now()
);

create table if not exists public.user_blocks(
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(blocker_id, blocked_id),
  check(blocker_id <> blocked_id)
);

create table if not exists public.certificates(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  issued_at timestamptz not null default now(),
  certificate_code text unique not null
);

alter table public.community_conversations enable row level security;
alter table public.verification_requests enable row level security;
alter table public.safety_reports enable row level security;
alter table public.user_blocks enable row level security;
alter table public.certificates enable row level security;

-- Policies are created only if absent so this migration can safely be reapplied after a partial run.
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='community_conversations' and policyname='community conversation members read') then
    create policy "community conversation members read" on public.community_conversations for select using (exists(select 1 from public.community_members cm where cm.community_id=community_conversations.community_id and cm.user_id=auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='verification_requests' and policyname='own verification requests') then
    create policy "own verification requests" on public.verification_requests for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='safety_reports' and policyname='own safety reports') then
    create policy "own safety reports" on public.safety_reports for insert with check(auth.uid()=reporter_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_blocks' and policyname='own blocks') then
    create policy "own blocks" on public.user_blocks for all using(auth.uid()=blocker_id) with check(auth.uid()=blocker_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='certificates' and policyname='own certificates') then
    create policy "own certificates" on public.certificates for select using(auth.uid()=user_id);
  end if;
end $$;

create or replace function public.get_or_create_community_conversation(p_community_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare cid uuid;
begin
  if not exists(select 1 from community_members where community_id=p_community_id and user_id=auth.uid()) then
    raise exception 'You must join the community before opening its chat';
  end if;
  select conversation_id into cid from community_conversations where community_id=p_community_id;
  if cid is null then
    insert into conversations(is_group) values(true) returning id into cid;
    insert into community_conversations(community_id,conversation_id) values(p_community_id,cid);
  end if;
  insert into conversation_members(conversation_id,user_id)
    select cid, user_id from community_members where community_id=p_community_id
    on conflict do nothing;
  return cid;
end $$;

create or replace function public.sync_community_chat_member()
returns trigger language plpgsql security definer set search_path=public as $$
declare cid uuid;
begin
  select conversation_id into cid from community_conversations where community_id=new.community_id;
  if cid is not null then
    insert into conversation_members(conversation_id,user_id) values(cid,new.user_id) on conflict do nothing;
  end if;
  return new;
end $$;

drop trigger if exists trg_sync_community_chat_member on public.community_members;
create trigger trg_sync_community_chat_member after insert on public.community_members for each row execute function public.sync_community_chat_member();

create or replace function public.notify_user(p_user_id uuid, p_title text, p_body text)
returns void language sql security definer set search_path=public as $$
  insert into public.notifications(user_id,title,body) values(p_user_id,p_title,p_body);
$$;

create or replace function public.notify_event_registration()
returns trigger language plpgsql security definer set search_path=public as $$
declare t text;
begin
  select title into t from events where id=new.event_id;
  perform notify_user(new.user_id,'Event registration confirmed',coalesce(t,'Event'));
  return new;
end $$;
drop trigger if exists trg_event_registration_notification on public.event_registrations;
create trigger trg_event_registration_notification after insert on public.event_registrations for each row execute function public.notify_event_registration();

create or replace function public.notify_funding_application()
returns trigger language plpgsql security definer set search_path=public as $$
declare t text;
begin
  select title into t from funding_opportunities where id=new.opportunity_id;
  perform notify_user(new.user_id,'Funding application submitted',coalesce(t,'Funding opportunity'));
  return new;
end $$;
drop trigger if exists trg_funding_application_notification on public.funding_applications;
create trigger trg_funding_application_notification after insert or update on public.funding_applications for each row execute function public.notify_funding_application();

create or replace function public.notify_project_join()
returns trigger language plpgsql security definer set search_path=public as $$
declare t text;
begin
  select title into t from projects where id=new.project_id;
  perform notify_user(new.user_id,'Project joined',coalesce(t,'Project'));
  return new;
end $$;
drop trigger if exists trg_project_join_notification on public.project_members;
create trigger trg_project_join_notification after insert on public.project_members for each row execute function public.notify_project_join();

-- Add an owner field only when the base table does not already have one.
do $$ begin
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='businesses' and column_name='owner_id') then
    alter table public.businesses add column owner_id uuid references public.profiles(id) on delete set null;
  end if;
end $$;

create or replace function public.notify_business_inquiry()
returns trigger language plpgsql security definer set search_path=public as $$
declare owner_id uuid; bname text;
begin
  select p.id,b.name into owner_id,bname from businesses b join profiles p on p.id=b.owner_id where b.id=new.business_id;
  if owner_id is not null then perform notify_user(owner_id,'New business inquiry',coalesce(bname,'Business')); end if;
  return new;
end $$;
drop trigger if exists trg_business_inquiry_notification on public.business_inquiries;
create trigger trg_business_inquiry_notification after insert on public.business_inquiries for each row execute function public.notify_business_inquiry();

create index if not exists idx_community_posts_community_created on public.community_posts(community_id,created_at desc);
create index if not exists idx_messages_conversation_created on public.messages(conversation_id,created_at);
create index if not exists idx_notifications_user_created on public.notifications(user_id,created_at desc);
create index if not exists idx_lessons_course_position on public.lessons(course_id,position);
create index if not exists idx_funding_apps_user on public.funding_applications(user_id,created_at desc);
create index if not exists idx_project_members_project on public.project_members(project_id);
