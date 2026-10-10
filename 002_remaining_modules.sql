create table if not exists public.communities(id uuid primary key default gen_random_uuid(),name text not null,description text default '',country text default '',created_at timestamptz default now());
create table if not exists public.events(id uuid primary key default gen_random_uuid(),title text not null,description text default '',country text default '',starts_at timestamptz,created_at timestamptz default now());
create table if not exists public.courses(id uuid primary key default gen_random_uuid(),title text not null,description text default '',level text default 'beginner',created_at timestamptz default now());
create table if not exists public.businesses(id uuid primary key default gen_random_uuid(),name text not null,description text default '',country text default '',verified boolean default false,created_at timestamptz default now());
create table if not exists public.funding_opportunities(id uuid primary key default gen_random_uuid(),title text not null,description text default '',type text default 'grant',created_at timestamptz default now());
create table if not exists public.projects(id uuid primary key default gen_random_uuid(),title text not null,description text default '',country text default '',status text default 'open',created_at timestamptz default now());
alter table public.communities enable row level security;
alter table public.events enable row level security;
alter table public.courses enable row level security;
alter table public.businesses enable row level security;
alter table public.funding_opportunities enable row level security;
alter table public.projects enable row level security;
create policy "communities public read" on public.communities for select using(true);
create policy "events public read" on public.events for select using(true);
create policy "courses public read" on public.courses for select using(true);
create policy "businesses public read" on public.businesses for select using(true);
create policy "funding public read" on public.funding_opportunities for select using(true);
create policy "projects public read" on public.projects for select using(true);

-- v0.5 functional module integration
create table if not exists public.community_members(
  community_id uuid references public.communities(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(), primary key(community_id,user_id)
);
create table if not exists public.community_posts(
  id uuid primary key default gen_random_uuid(), community_id uuid references public.communities(id) on delete cascade,
  author_id uuid references public.profiles(id) on delete cascade, body text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.event_registrations(
  event_id uuid references public.events(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  registered_at timestamptz not null default now(), primary key(event_id,user_id)
);
create table if not exists public.lessons(
  id uuid primary key default gen_random_uuid(), course_id uuid references public.courses(id) on delete cascade,
  title text not null, content text default '', position int not null default 1
);
create table if not exists public.course_enrollments(
  course_id uuid references public.courses(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  enrolled_at timestamptz not null default now(), primary key(course_id,user_id)
);
create table if not exists public.lesson_progress(
  lesson_id uuid references public.lessons(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  completed boolean not null default false, updated_at timestamptz not null default now(), primary key(lesson_id,user_id)
);
create table if not exists public.quizzes(
  id uuid primary key default gen_random_uuid(), course_id uuid references public.courses(id) on delete cascade,
  title text not null, questions jsonb not null default '[]'::jsonb
);
create table if not exists public.quiz_attempts(
  id uuid primary key default gen_random_uuid(), quiz_id uuid references public.quizzes(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade, score numeric default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.marketplace_listings(
  id uuid primary key default gen_random_uuid(), business_id uuid references public.businesses(id) on delete cascade,
  title text not null, description text default '', price numeric, currency text default 'USD', created_at timestamptz not null default now()
);
create table if not exists public.business_inquiries(
  id uuid primary key default gen_random_uuid(), business_id uuid references public.businesses(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade, message text not null,
  status text not null default 'open', created_at timestamptz not null default now()
);
create table if not exists public.business_partnerships(
  id uuid primary key default gen_random_uuid(), business_id uuid references public.businesses(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade, message text default '', status text not null default 'pending', created_at timestamptz not null default now()
);
create table if not exists public.funding_applications(
  id uuid primary key default gen_random_uuid(), opportunity_id uuid references public.funding_opportunities(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade, statement text default '', status text not null default 'draft', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.project_members(
  project_id uuid references public.projects(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(), primary key(project_id,user_id)
);
create table if not exists public.project_skills(
  id uuid primary key default gen_random_uuid(), project_id uuid references public.projects(id) on delete cascade,
  skill text not null
);

alter table public.community_members enable row level security;
alter table public.community_posts enable row level security;
alter table public.event_registrations enable row level security;
alter table public.lessons enable row level security;
alter table public.course_enrollments enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.marketplace_listings enable row level security;
alter table public.business_inquiries enable row level security;
alter table public.business_partnerships enable row level security;
alter table public.funding_applications enable row level security;
alter table public.project_members enable row level security;
alter table public.project_skills enable row level security;

create policy "community members readable" on public.community_members for select using (auth.uid() is not null);
create policy "own community membership" on public.community_members for insert with check(auth.uid()=user_id);
create policy "own community leave" on public.community_members for delete using(auth.uid()=user_id);
create policy "community posts readable" on public.community_posts for select using(true);
create policy "own community post" on public.community_posts for insert with check(auth.uid()=author_id and exists(select 1 from community_members m where m.community_id=community_posts.community_id and m.user_id=auth.uid()));
create policy "own community post update" on public.community_posts for update using(auth.uid()=author_id) with check(auth.uid()=author_id);
create policy "own event registration" on public.event_registrations for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "lessons public read" on public.lessons for select using(true);
create policy "own enrollment" on public.course_enrollments for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "own lesson progress" on public.lesson_progress for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "quizzes public read" on public.quizzes for select using(true);
create policy "own quiz attempts" on public.quiz_attempts for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "listings public read" on public.marketplace_listings for select using(true);
create policy "own business inquiry" on public.business_inquiries for insert with check(auth.uid()=user_id);
create policy "own business inquiry read" on public.business_inquiries for select using(auth.uid()=user_id);
create policy "own partnership" on public.business_partnerships for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "own funding application" on public.funding_applications for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "project members readable" on public.project_members for select using(auth.uid() is not null);
create policy "own project membership" on public.project_members for insert with check(auth.uid()=user_id);
create policy "own project leave" on public.project_members for delete using(auth.uid()=user_id);
create policy "project skills public read" on public.project_skills for select using(true);
