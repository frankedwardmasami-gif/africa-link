-- AFRICA LINK v0.6 integration core
-- Run after 003_functional_hardening.sql.
create index if not exists idx_profiles_username on public.profiles(username);
create index if not exists idx_profiles_citizenship on public.profiles(african_citizenship);
create index if not exists idx_communities_name on public.communities(name);
create index if not exists idx_events_title on public.events(title);
create index if not exists idx_courses_title on public.courses(title);
create index if not exists idx_businesses_name on public.businesses(name);
create index if not exists idx_projects_title on public.projects(title);
create index if not exists idx_funding_title on public.funding_opportunities(title);
-- Prevent users from changing ownership fields through client writes.
drop policy if exists "own blocks" on public.user_blocks;
create policy "own blocks" on public.user_blocks for all using(auth.uid()=blocker_id) with check(auth.uid()=blocker_id and blocker_id=auth.uid());
-- Basic uniqueness/consistency for verification requests.
create unique index if not exists uq_pending_verification_user on public.verification_requests(user_id) where status='pending';
