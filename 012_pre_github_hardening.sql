-- AFRICA LINK v1.4 pre-GitHub hardening.
-- Run after 011_final_production_systems.sql.
-- This migration closes release-blocking gaps found during static review.

-- Safety moderation fields used by the admin resolution RPC.
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='safety_reports' and column_name='admin_note'
  ) then
    alter table public.safety_reports add column admin_note text not null default '';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='safety_reports' and column_name='updated_at'
  ) then
    alter table public.safety_reports add column updated_at timestamptz not null default now();
  end if;
end $$;

-- Moderators/admins need to read the moderation queue; normal users keep insert-only access.
drop policy if exists "admin safety reports read" on public.safety_reports;
create policy "admin safety reports read"
  on public.safety_reports for select
  using (public.is_platform_admin());

-- Profile visibility is now enforced by the database instead of being UI-only.
create or replace function public.can_view_profile(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path=public,pg_temp
as $$
  select
    (
      auth.uid() = p_profile_id
      or exists (
        select 1
        from public.user_preferences pref
        where pref.user_id = p_profile_id
          and pref.profile_visibility = 'public'
      )
      or (
        exists (
          select 1
          from public.user_preferences pref
          where pref.user_id = p_profile_id
            and pref.profile_visibility = 'connections'
        )
        and exists (
          select 1
          from public.user_connections c
          where c.status = 'accepted'
            and ((c.requester_id = auth.uid() and c.addressee_id = p_profile_id)
              or (c.requester_id = p_profile_id and c.addressee_id = auth.uid()))
        )
      )
    )
    and not exists (
      select 1
      from public.user_blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = p_profile_id)
         or (b.blocker_id = p_profile_id and b.blocked_id = auth.uid())
    );
$$;

grant execute on function public.can_view_profile(uuid) to authenticated;

drop policy if exists "profiles readable" on public.profiles;
drop policy if exists "profiles visibility" on public.profiles;
create policy "profiles visibility"
  on public.profiles for select
  using (public.can_view_profile(id));

-- Connection requests now honor the target user's privacy preference.
create or replace function public.request_connection(p_other_user_id uuid)
returns text
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare existing record;
begin
  if auth.uid() is null or p_other_user_id = auth.uid() then
    return 'invalid';
  end if;

  if not exists (select 1 from public.profiles where id=p_other_user_id) then
    return 'not_found';
  end if;

  if not coalesce(
    (select allow_connection_requests from public.user_preferences where user_id=p_other_user_id),
    true
  ) then
    return 'disabled';
  end if;

  if exists (
    select 1 from public.user_blocks b
    where (b.blocker_id=auth.uid() and b.blocked_id=p_other_user_id)
       or (b.blocker_id=p_other_user_id and b.blocked_id=auth.uid())
  ) then
    return 'blocked';
  end if;

  select * into existing
  from public.user_connections
  where (requester_id=auth.uid() and addressee_id=p_other_user_id)
     or (requester_id=p_other_user_id and addressee_id=auth.uid())
  limit 1;

  if existing is not null then
    if existing.status='declined' then
      update public.user_connections
      set requester_id=auth.uid(), addressee_id=p_other_user_id,
          status='pending', updated_at=now()
      where requester_id=existing.requester_id
        and addressee_id=existing.addressee_id;
      return 'pending';
    end if;
    return existing.status;
  end if;

  insert into public.user_connections(requester_id,addressee_id,status)
  values(auth.uid(),p_other_user_id,'pending');
  return 'pending';
end $$;

grant execute on function public.request_connection(uuid) to authenticated;

-- Direct messaging now honors allow_direct_messages and connection state.
create or replace function public.get_or_create_direct_conversation(other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare cid uuid;
  allowed text;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if other_user_id = auth.uid() then raise exception 'Cannot message yourself'; end if;
  if not exists (select 1 from public.profiles where id=other_user_id) then raise exception 'User not found'; end if;

  if exists (
    select 1 from public.user_blocks b
    where (b.blocker_id=auth.uid() and b.blocked_id=other_user_id)
       or (b.blocker_id=other_user_id and b.blocked_id=auth.uid())
  ) then
    raise exception 'Messaging is blocked between these users';
  end if;

  select coalesce(pref.allow_direct_messages,'connections') into allowed
  from public.user_preferences pref
  where pref.user_id=other_user_id;
  if allowed is null then allowed := 'connections'; end if;

  if allowed='nobody' then
    raise exception 'This user does not accept direct messages';
  end if;

  if allowed='connections' and not exists (
    select 1 from public.user_connections c
    where c.status='accepted'
      and ((c.requester_id=auth.uid() and c.addressee_id=other_user_id)
        or (c.requester_id=other_user_id and c.addressee_id=auth.uid()))
  ) then
    raise exception 'You must be connected before messaging this user';
  end if;

  select c.id into cid
  from public.conversations c
  join public.conversation_members a on a.conversation_id=c.id and a.user_id=auth.uid()
  join public.conversation_members b on b.conversation_id=c.id and b.user_id=other_user_id
  where c.is_group=false
  limit 1;

  if cid is null then
    insert into public.conversations(is_group) values(false) returning id into cid;
    insert into public.conversation_members(conversation_id,user_id)
    values(cid,auth.uid()),(cid,other_user_id);
  end if;
  return cid;
end $$;

grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;

-- Internal SECURITY DEFINER functions are not public APIs. Only the explicit client RPCs
-- retain EXECUTE permission; trigger functions are invoked by PostgreSQL itself.
revoke all on function public.notify_user(uuid,text,text) from public, anon, authenticated;
revoke all on function public.sync_community_chat_member() from public, anon, authenticated;
revoke all on function public.notify_event_registration() from public, anon, authenticated;
revoke all on function public.notify_funding_application() from public, anon, authenticated;
revoke all on function public.notify_project_join() from public, anon, authenticated;
revoke all on function public.notify_business_inquiry() from public, anon, authenticated;
revoke all on function public.notify_connection_request() from public, anon, authenticated;
revoke all on function public.sync_community_chat_member_delete() from public, anon, authenticated;
revoke all on function public.notify_post_like() from public, anon, authenticated;
revoke all on function public.notify_post_comment() from public, anon, authenticated;
revoke all on function public.notify_new_message() from public, anon, authenticated;
revoke all on function public.notify_connection_response() from public, anon, authenticated;
revoke all on function public.notify_business_partnership() from public, anon, authenticated;
revoke all on function public.sync_verification_profile() from public, anon, authenticated;

-- Keep direct/community conversation RPCs available only to signed-in users.
grant execute on function public.get_or_create_community_conversation(uuid) to authenticated;

-- Explicit RPC grants: deny anonymous/public execution of security-sensitive APIs.
revoke all on function public.can_view_profile(uuid) from public, anon;
grant execute on function public.can_view_profile(uuid) to authenticated;
revoke all on function public.get_or_create_community_conversation(uuid) from public, anon;
grant execute on function public.get_or_create_community_conversation(uuid) to authenticated;
revoke all on function public.get_or_create_direct_conversation(uuid) from public, anon;
grant execute on function public.get_or_create_direct_conversation(uuid) to authenticated;
revoke all on function public.request_connection(uuid) from public, anon;
grant execute on function public.request_connection(uuid) to authenticated;
revoke all on function public.respond_connection(uuid,boolean) from public, anon;
grant execute on function public.respond_connection(uuid,boolean) to authenticated;
revoke all on function public.submit_verification(text,text) from public, anon;
grant execute on function public.submit_verification(text,text) to authenticated;
revoke all on function public.is_platform_admin() from public, anon;
grant execute on function public.is_platform_admin() to authenticated;
revoke all on function public.review_verification(uuid,text,text) from public, anon;
grant execute on function public.review_verification(uuid,text,text) to authenticated;
revoke all on function public.save_user_preferences(text,boolean,boolean,text,text,boolean) from public, anon;
grant execute on function public.save_user_preferences(text,boolean,boolean,text,text,boolean) to authenticated;
revoke all on function public.request_account_deletion(text) from public, anon;
grant execute on function public.request_account_deletion(text) to authenticated;
revoke all on function public.cancel_account_deletion() from public, anon;
grant execute on function public.cancel_account_deletion() to authenticated;
revoke all on function public.admin_resolve_report(uuid,text,text) from public, anon;
grant execute on function public.admin_resolve_report(uuid,text,text) to authenticated;
revoke all on function public.admin_review_deletion(uuid,boolean) from public, anon;
grant execute on function public.admin_review_deletion(uuid,boolean) to authenticated;
revoke all on function public.register_push_device(text,text) from public, anon;
grant execute on function public.register_push_device(text,text) to authenticated;
revoke all on function public.save_notification_preferences(boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean) from public, anon;
grant execute on function public.save_notification_preferences(boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean) to authenticated;
revoke all on function public.create_content_report(text,text,text,text) from public, anon;
grant execute on function public.create_content_report(text,text,text,text) to authenticated;

-- Private storage buckets with user-scoped object paths.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values
  ('avatars','avatars',false,5242880,array['image/jpeg','image/png','image/webp']),
  ('media','media',false,15728640,array['image/jpeg','image/png','image/webp','video/mp4','audio/mpeg','audio/mp4']),
  ('documents','documents',false,15728640,array['application/pdf','image/jpeg','image/png'])
on conflict (id) do update set
  public=excluded.public,
  file_size_limit=excluded.file_size_limit,
  allowed_mime_types=excluded.allowed_mime_types;

-- Storage object paths must begin with the authenticated user's UUID.
drop policy if exists "africa link storage read own" on storage.objects;
drop policy if exists "africa link storage insert own" on storage.objects;
drop policy if exists "africa link storage update own" on storage.objects;
drop policy if exists "africa link storage delete own" on storage.objects;

create policy "africa link storage read own"
  on storage.objects for select to authenticated
  using (
    bucket_id in ('avatars','media','documents')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "africa link storage insert own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id in ('avatars','media','documents')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "africa link storage update own"
  on storage.objects for update to authenticated
  using (
    bucket_id in ('avatars','media','documents')
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id in ('avatars','media','documents')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "africa link storage delete own"
  on storage.objects for delete to authenticated
  using (
    bucket_id in ('avatars','media','documents')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Keep SECURITY DEFINER functions on a trusted schema path with pg_temp last.
alter function public.get_or_create_direct_conversation(uuid) set search_path=public,pg_temp;
alter function public.get_or_create_community_conversation(uuid) set search_path=public,pg_temp;
alter function public.sync_community_chat_member() set search_path=public,pg_temp;
alter function public.notify_user(uuid,text,text) set search_path=public,pg_temp;
alter function public.notify_event_registration() set search_path=public,pg_temp;
alter function public.notify_funding_application() set search_path=public,pg_temp;
alter function public.notify_project_join() set search_path=public,pg_temp;
alter function public.notify_business_inquiry() set search_path=public,pg_temp;
alter function public.notify_connection_request() set search_path=public,pg_temp;
alter function public.request_connection(uuid) set search_path=public,pg_temp;
alter function public.sync_community_chat_member_delete() set search_path=public,pg_temp;
alter function public.notify_post_like() set search_path=public,pg_temp;
alter function public.notify_post_comment() set search_path=public,pg_temp;
alter function public.notify_new_message() set search_path=public,pg_temp;
alter function public.notify_connection_response() set search_path=public,pg_temp;
alter function public.notify_business_partnership() set search_path=public,pg_temp;
alter function public.respond_connection(uuid,boolean) set search_path=public,pg_temp;
alter function public.submit_verification(text,text) set search_path=public,pg_temp;
alter function public.is_platform_admin() set search_path=public,pg_temp;
alter function public.review_verification(uuid,text,text) set search_path=public,pg_temp;
alter function public.sync_verification_profile() set search_path=public,pg_temp;
alter function public.save_user_preferences(text,boolean,boolean,text,text,boolean) set search_path=public,pg_temp;
alter function public.request_account_deletion(text) set search_path=public,pg_temp;
alter function public.cancel_account_deletion() set search_path=public,pg_temp;
alter function public.admin_resolve_report(uuid,text,text) set search_path=public,pg_temp;
alter function public.admin_review_deletion(uuid,boolean) set search_path=public,pg_temp;
alter function public.register_push_device(text,text) set search_path=public,pg_temp;
alter function public.save_notification_preferences(boolean,boolean,boolean,boolean,boolean,boolean,boolean,boolean) set search_path=public,pg_temp;
alter function public.create_content_report(text,text,text,text) set search_path=public,pg_temp;
alter function public.can_view_profile(uuid) set search_path=public,pg_temp;
