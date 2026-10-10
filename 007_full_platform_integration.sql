-- AFRICA LINK v0.9 Full Platform Integration
-- Run after 006_advanced_social_collaboration.sql.

-- Correct legacy index target if the v0.6 migration was previously applied with the old name.
drop index if exists public.idx_profiles_citizenship;
create index if not exists idx_profiles_african_citizenship on public.profiles(african_citizenship);

-- Ensure common feed and collaboration paths are indexed.
create index if not exists idx_posts_created on public.posts(created_at desc);
create index if not exists idx_post_likes_user on public.post_likes(user_id,created_at desc);
create index if not exists idx_messages_sender_created on public.messages(sender_id,created_at desc);
create index if not exists idx_conversation_members_user on public.conversation_members(user_id,conversation_id);
create index if not exists idx_notifications_unread on public.notifications(user_id,read,created_at desc);
create index if not exists idx_business_inquiries_business on public.business_inquiries(business_id,created_at desc);
create index if not exists idx_business_partnerships_business on public.business_partnerships(business_id,created_at desc);

-- Keep community chat membership synchronized on both join and leave.
create or replace function public.sync_community_chat_member_delete()
returns trigger language plpgsql security definer set search_path=public as $$
declare cid uuid;
begin
  select conversation_id into cid from community_conversations where community_id=old.community_id;
  if cid is not null then
    delete from conversation_members where conversation_id=cid and user_id=old.user_id;
  end if;
  return old;
end $$;

drop trigger if exists trg_sync_community_chat_member_delete on public.community_members;
create trigger trg_sync_community_chat_member_delete after delete on public.community_members
for each row execute function public.sync_community_chat_member_delete();

-- Notify the author when another member likes/comments on a post.
create or replace function public.notify_post_like()
returns trigger language plpgsql security definer set search_path=public as $$
declare author uuid; actor text;
begin
  select author_id into author from posts where id=new.post_id;
  select coalesce(full_name,'Someone') into actor from profiles where id=new.user_id;
  if author is not null and author<>new.user_id then
    perform notify_user(author,'Post liked',actor || ' liked your post.');
  end if;
  return new;
end $$;

drop trigger if exists trg_post_like_notification on public.post_likes;
create trigger trg_post_like_notification after insert on public.post_likes for each row execute function public.notify_post_like();

create or replace function public.notify_post_comment()
returns trigger language plpgsql security definer set search_path=public as $$
declare author uuid; actor text;
begin
  select author_id into author from posts where id=new.post_id;
  select coalesce(full_name,'Someone') into actor from profiles where id=new.author_id;
  if author is not null and author<>new.author_id then
    perform notify_user(author,'New comment',actor || ' commented on your post.');
  end if;
  return new;
end $$;

drop trigger if exists trg_post_comment_notification on public.comments;
create trigger trg_post_comment_notification after insert on public.comments for each row execute function public.notify_post_comment();

-- Notify users participating in a direct/group conversation when a new message arrives.
create or replace function public.notify_new_message()
returns trigger language plpgsql security definer set search_path=public as $$
declare actor text;
begin
  select coalesce(full_name,'Someone') into actor from profiles where id=new.sender_id;
  insert into notifications(user_id,title,body)
  select cm.user_id,'New message',actor || ' sent you a message.'
  from conversation_members cm
  where cm.conversation_id=new.conversation_id and cm.user_id<>new.sender_id;
  return new;
end $$;

drop trigger if exists trg_new_message_notification on public.messages;
create trigger trg_new_message_notification after insert on public.messages for each row execute function public.notify_new_message();

-- Notify the requester when a connection is accepted.
create or replace function public.notify_connection_response()
returns trigger language plpgsql security definer set search_path=public as $$
declare actor text;
begin
  if new.status='accepted' and old.status is distinct from new.status then
    select coalesce(full_name,'Someone') into actor from profiles where id=new.addressee_id;
    perform notify_user(new.requester_id,'Connection accepted',actor || ' accepted your connection request.');
  end if;
  return new;
end $$;

drop trigger if exists trg_connection_response_notification on public.user_connections;
create trigger trg_connection_response_notification after update on public.user_connections for each row execute function public.notify_connection_response();

-- Notify business owners about partnership requests too.
create or replace function public.notify_business_partnership()
returns trigger language plpgsql security definer set search_path=public as $$
declare owner_id uuid; bname text;
begin
  select b.owner_id,b.name into owner_id,bname from businesses b where b.id=new.business_id;
  if owner_id is not null and owner_id<>new.user_id then
    perform notify_user(owner_id,'New partnership request',coalesce(bname,'Business'));
  end if;
  return new;
end $$;

drop trigger if exists trg_business_partnership_notification on public.business_partnerships;
create trigger trg_business_partnership_notification after insert on public.business_partnerships for each row execute function public.notify_business_partnership();

-- Realtime for all major interaction tables.
do $$ begin alter publication supabase_realtime add table public.user_connections; exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.post_likes; exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.comments; exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.messages; exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.notifications; exception when duplicate_object then null; when undefined_object then null; end $$;

-- Security: notification reads/updates remain user-scoped; message membership remains conversation-scoped.
