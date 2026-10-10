create extension if not exists pgcrypto;

create table if not exists public.profiles(
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 username text unique not null default '',
 email text, phone text, photo_url text,
 african_citizenship text, current_country text,
 languages text[] not null default '{}',
 skills text[] not null default '{}',
 interests text[] not null default '{}',
 bio text, verification_status text not null default 'unverified',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.posts(
 id uuid primary key default gen_random_uuid(), author_id uuid not null references public.profiles(id) on delete cascade,
 body text not null, created_at timestamptz not null default now()
);
create table if not exists public.post_likes(
 post_id uuid references public.posts(id) on delete cascade, user_id uuid references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(post_id,user_id)
);
create table if not exists public.comments(
 id uuid primary key default gen_random_uuid(), post_id uuid references public.posts(id) on delete cascade,
 author_id uuid references public.profiles(id) on delete cascade, body text not null,
 created_at timestamptz not null default now()
);

create table if not exists public.conversations(
 id uuid primary key default gen_random_uuid(), is_group boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.conversation_members(
 conversation_id uuid references public.conversations(id) on delete cascade,
 user_id uuid references public.profiles(id) on delete cascade,
 primary key(conversation_id,user_id)
);
create table if not exists public.messages(
 id uuid primary key default gen_random_uuid(), conversation_id uuid references public.conversations(id) on delete cascade,
 sender_id uuid references public.profiles(id) on delete cascade, body text not null,
 created_at timestamptz not null default now()
);

create table if not exists public.opportunities(
 id uuid primary key default gen_random_uuid(), title text not null, type text,
 description text, country text, skills text[] default '{}', deadline timestamptz,
 application_url text, created_at timestamptz not null default now()
);
create table if not exists public.opportunity_saves(
 opportunity_id uuid references public.opportunities(id) on delete cascade,
 user_id uuid references public.profiles(id) on delete cascade,
 primary key(opportunity_id,user_id)
);

create table if not exists public.notifications(
 id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(id) on delete cascade,
 title text not null, body text not null, read boolean not null default false,
 created_at timestamptz not null default now()
);

create or replace view public.feed_posts as
select p.id,p.author_id,pr.full_name as author_name,pr.photo_url as author_photo,p.body,p.created_at,
 (select count(*) from public.post_likes l where l.post_id=p.id)::int as like_count,
 (select count(*) from public.comments c where c.post_id=p.id)::int as comment_count
from public.posts p join public.profiles pr on pr.id=p.author_id;

create or replace function public.get_or_create_direct_conversation(other_user_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare cid uuid;
begin
 select c.id into cid from conversations c
 join conversation_members a on a.conversation_id=c.id and a.user_id=auth.uid()
 join conversation_members b on b.conversation_id=c.id and b.user_id=other_user_id
 where c.is_group=false limit 1;
 if cid is null then
   insert into conversations(is_group) values(false) returning id into cid;
   insert into conversation_members values(cid,auth.uid()),(cid,other_user_id);
 end if;
 return cid;
end $$;

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.comments enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.opportunities enable row level security;
alter table public.opportunity_saves enable row level security;
alter table public.notifications enable row level security;

create policy "profiles readable" on public.profiles for select using (true);
create policy "own profile write" on public.profiles for all using(auth.uid()=id) with check(auth.uid()=id);
create policy "posts readable" on public.posts for select using(true);
create policy "own posts create" on public.posts for insert with check(auth.uid()=author_id);
create policy "own posts update" on public.posts for update using(auth.uid()=author_id);
create policy "own posts delete" on public.posts for delete using(auth.uid()=author_id);
create policy "likes readable" on public.post_likes for select using(true);
create policy "own like" on public.post_likes for insert with check(auth.uid()=user_id);
create policy "own like delete" on public.post_likes for delete using(auth.uid()=user_id);
create policy "comments readable" on public.comments for select using(true);
create policy "comment own" on public.comments for all using(auth.uid()=author_id) with check(auth.uid()=author_id);
create policy "opportunities readable" on public.opportunities for select using(true);
create policy "save own opportunity" on public.opportunity_saves for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "conversation members" on public.conversation_members for select using(auth.uid()=user_id);
create policy "messages members read" on public.messages for select using(exists(select 1 from conversation_members m where m.conversation_id=messages.conversation_id and m.user_id=auth.uid()));
create policy "messages own send" on public.messages for insert with check(auth.uid()=sender_id and exists(select 1 from conversation_members m where m.conversation_id=messages.conversation_id and m.user_id=auth.uid()));
create policy "notifications own" on public.notifications for select using(auth.uid()=user_id);
create policy "notifications mark" on public.notifications for update using(auth.uid()=user_id);

alter publication supabase_realtime add table public.posts, public.messages, public.notifications;
