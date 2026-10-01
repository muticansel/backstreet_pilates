-- Admins record the attendance outcome of a completed booked session.
begin;

create or replace function public.admin_record_booking_attendance(
  target_booking_id uuid,
  target_status text
)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not (select private.is_admin()) then
    raise exception 'Admin access required';
  end if;
  if target_status not in ('attended', 'no_show') then
    raise exception 'Attendance status must be attended or no_show';
  end if;

  update public.bookings booking
  set status = target_status
  where booking.id = target_booking_id
    and booking.status in ('booked', 'attended', 'no_show')
    and exists (
      select 1
      from public.class_sessions session
      where session.id = booking.class_session_id
        and session.starts_at < now()
    );

  if not found then
    raise exception 'This booking is not a completed class awaiting attendance';
  end if;
end;
$$;

revoke all on function public.admin_record_booking_attendance(uuid, text)
  from public, anon, authenticated;
grant execute on function public.admin_record_booking_attendance(uuid, text)
  to authenticated;

commit;
