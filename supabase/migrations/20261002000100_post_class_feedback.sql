-- A member can record two short ratings for an attended class only.
-- Studio admins can read the resulting history for instructor follow-up.
begin;

create table public.class_feedback (
  booking_id uuid primary key references public.bookings(id) on delete cascade,
  enjoyment integer not null check (enjoyment between 1 and 3),
  difficulty integer not null check (difficulty between 1 and 3),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.class_feedback enable row level security;
revoke all on public.class_feedback from anon, authenticated;
grant select, insert, update on public.class_feedback to authenticated;

create policy feedback_read on public.class_feedback for select to authenticated
using (
  (select private.is_admin())
  or exists (
    select 1 from public.bookings booking
    where booking.id = booking_id and booking.user_id = (select auth.uid())
  )
);

create policy feedback_insert_own_attended on public.class_feedback for insert to authenticated
with check (
  exists (
    select 1 from public.bookings booking
    where booking.id = booking_id
      and booking.user_id = (select auth.uid())
      and booking.status = 'attended'
  )
);

create policy feedback_update_own_attended on public.class_feedback for update to authenticated
using (
  exists (
    select 1 from public.bookings booking
    where booking.id = booking_id and booking.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.bookings booking
    where booking.id = booking_id
      and booking.user_id = (select auth.uid())
      and booking.status = 'attended'
  )
);

commit;
