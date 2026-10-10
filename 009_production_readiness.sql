-- AFRICA LINK v1.0.1 Production Readiness Hardening
-- Run after 008_release_hardening.sql.

-- Verification requests must go through the controlled submission RPC.
drop policy if exists "own verification requests" on public.verification_requests;
create policy "own verification requests read" on public.verification_requests for select using(auth.uid()=user_id);

-- Prevent duplicate active event registrations, course enrollment and project membership.
create unique index if not exists uq_event_registration_user_event on public.event_registrations(event_id,user_id);
create unique index if not exists uq_course_enrollment_user_course on public.course_enrollments(course_id,user_id);
create unique index if not exists uq_project_member_user_project on public.project_members(project_id,user_id);

-- Helpful lookup indexes for moderation and profile discovery.
create index if not exists idx_safety_reports_status_created on public.safety_reports(status,created_at desc);
create index if not exists idx_user_blocks_blocked on public.user_blocks(blocked_id);
create index if not exists idx_profiles_current_country on public.profiles(current_country);

-- Keep verification state synchronized when a reviewer changes a request.
create or replace function public.sync_verification_profile()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  update public.profiles set
    verification_status=case when new.status='approved' then 'verified' when new.status='rejected' then 'rejected' else 'pending' end,
    updated_at=now()
  where id=new.user_id;
  return new;
end $$;
drop trigger if exists trg_sync_verification_profile on public.verification_requests;
create trigger trg_sync_verification_profile after insert or update of status on public.verification_requests
for each row execute function public.sync_verification_profile();
