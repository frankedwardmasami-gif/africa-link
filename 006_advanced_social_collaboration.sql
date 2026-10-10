-- AFRICA LINK v0.8 Advanced Social & Collaboration Layer
-- Run after 005_platform_experience.sql.

create index if not exists idx_comments_author on public.comments(author_id, created_at desc);
create index if not exists idx_posts_author_created on public.posts(author_id, created_at desc);
create index if not exists idx_event_reg_user on public.event_registrations(user_id, registered_at desc);
create index if not exists idx_project_members_user on public.project_members(user_id, joined_at desc);
create index if not exists idx_marketplace_business_created on public.marketplace_listings(business_id, created_at desc);

-- Safer connection request flow: prevents duplicate reverse-direction rows.
create or replace function public.request_connection(p_other_user_id uuid)
returns text language plpgsql security definer set search_path=public as $$
declare existing record;
begin
  if auth.uid() is null or p_other_user_id = auth.uid() then return 'invalid'; end if;
  select * into existing from user_connections
   where (requester_id=auth.uid() and addressee_id=p_other_user_id)
      or (requester_id=p_other_user_id and addressee_id=auth.uid())
   limit 1;
  if existing is not null then
    if existing.status='declined' then
      update user_connections set requester_id=auth.uid(), addressee_id=p_other_user_id, status='pending', updated_at=now()
      where requester_id=existing.requester_id and addressee_id=existing.addressee_id;
      return 'pending';
    end if;
    return existing.status;
  end if;
  insert into user_connections(requester_id,addressee_id,status) values(auth.uid(),p_other_user_id,'pending');
  return 'pending';
end $$;

grant execute on function public.request_connection(uuid) to authenticated;

-- Rich comment read surface for the app.
drop view if exists public.post_comments;
create view public.post_comments as
select c.id,c.post_id,c.author_id,pr.full_name as author_name,pr.username as author_username,pr.photo_url as author_photo,c.body,c.created_at
from public.comments c join public.profiles pr on pr.id=c.author_id;

-- Public marketplace listing detail surface.
drop view if exists public.marketplace_feed;
create view public.marketplace_feed as
select l.id,l.business_id,b.name as business_name,b.verified,l.title,l.description,l.price,l.currency,l.created_at
from public.marketplace_listings l join public.businesses b on b.id=l.business_id;

-- Realtime for comments and connection state is already enabled in v0.7; add registrations/members where supported.
do $$ begin alter publication supabase_realtime add table public.event_registrations; exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.project_members; exception when duplicate_object then null; when undefined_object then null; end $$;
