-- AFRICA LINK v0.7 Platform Experience
-- Run after 004_integration_core.sql.

create table if not exists public.user_connections(
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check(status in ('pending','accepted','declined','blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key(requester_id,addressee_id), check(requester_id<>addressee_id)
);
alter table public.user_connections enable row level security;

do $$ begin
 if not exists(select 1 from pg_policies where tablename='user_connections' and policyname='connections participants read') then
  create policy "connections participants read" on public.user_connections for select using(auth.uid()=requester_id or auth.uid()=addressee_id);
 end if;
 if not exists(select 1 from pg_policies where tablename='user_connections' and policyname='connection request own') then
  create policy "connection request own" on public.user_connections for insert with check(auth.uid()=requester_id);
 end if;
 if not exists(select 1 from pg_policies where tablename='user_connections' and policyname='connection update participants') then
  create policy "connection update participants" on public.user_connections for update using(auth.uid()=requester_id or auth.uid()=addressee_id) with check(auth.uid()=requester_id or auth.uid()=addressee_id);
 end if;
 if not exists(select 1 from pg_policies where tablename='user_connections' and policyname='connection delete participants') then
  create policy "connection delete participants" on public.user_connections for delete using(auth.uid()=requester_id or auth.uid()=addressee_id);
 end if;
end $$;

create index if not exists idx_connections_requester on public.user_connections(requester_id,status);
create index if not exists idx_connections_addressee on public.user_connections(addressee_id,status);

-- Harden post engagement ownership and expose comment/like totals through the feed view.
drop view if exists public.feed_posts;
create view public.feed_posts as
select p.id,p.author_id,pr.full_name as author_name,pr.username as author_username,pr.photo_url as author_photo,p.body,p.created_at,
 (select count(*) from public.post_likes l where l.post_id=p.id)::int as like_count,
 (select count(*) from public.comments c where c.post_id=p.id)::int as comment_count
from public.posts p join public.profiles pr on pr.id=p.author_id;

-- Make realtime available for the main social surfaces where possible.
do $$ begin
 alter publication supabase_realtime add table public.post_likes;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
 alter publication supabase_realtime add table public.comments;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
 alter publication supabase_realtime add table public.user_connections;
exception when duplicate_object then null; when undefined_object then null; end $$;

-- Helpful notification trigger for connection requests.
create or replace function public.notify_connection_request()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 perform notify_user(new.addressee_id,'New connection request',coalesce((select full_name from profiles where id=new.requester_id),'Someone') || ' wants to connect with you.');
 return new;
end $$;
drop trigger if exists trg_connection_request_notification on public.user_connections;
create trigger trg_connection_request_notification after insert on public.user_connections for each row execute function public.notify_connection_request();

-- Prevent duplicate active event registrations and normalize common status values.
create index if not exists idx_event_registrations_event on public.event_registrations(event_id);
create index if not exists idx_course_enrollments_user on public.course_enrollments(user_id);
create index if not exists idx_comments_post_created on public.comments(post_id,created_at desc);
create index if not exists idx_post_likes_post on public.post_likes(post_id);
