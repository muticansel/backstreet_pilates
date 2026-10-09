-- Restores the member's read path for their own private-lesson requests.
-- This is intentionally idempotent because early calendar setup may have
-- been applied in more than one step.
begin;

grant select on public.private_lesson_requests to authenticated;

drop policy if exists private_lesson_requests_read
  on public.private_lesson_requests;
create policy private_lesson_requests_read
  on public.private_lesson_requests
  for select to authenticated
  using (
    member_user_id = (select auth.uid())
    or (select private.is_admin())
  );

commit;
