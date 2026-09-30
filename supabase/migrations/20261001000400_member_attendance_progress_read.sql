-- Let a member read the dated session behind their own booking so the app can
-- derive their completed-class progress. Booking RLS still limits the rows to
-- that member; this does not grant access to other members' bookings.
begin;

drop policy if exists sessions_read on public.class_sessions;
create policy sessions_read on public.class_sessions
for select to authenticated
using (
  status = 'scheduled'
  or exists (
    select 1
    from public.bookings booking
    where booking.class_session_id = class_sessions.id
      and booking.user_id = (select auth.uid())
  )
  or (select private.is_admin())
);

commit;
