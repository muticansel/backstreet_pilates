-- One read-only, admin-only snapshot for the operational "Today" page.
-- Calendar boundaries are Istanbul local time so a session is never assigned
-- to the wrong operational day by the device's time zone.
begin;

create function public.admin_today_operations()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
  start_of_day timestamptz := ((now() at time zone 'Europe/Istanbul')::date::timestamp at time zone 'Europe/Istanbul');
  end_of_day timestamptz := (((now() at time zone 'Europe/Istanbul')::date + 1)::timestamp at time zone 'Europe/Istanbul');
begin
  if not (select private.is_admin()) then
    raise exception 'Admin access required';
  end if;

  return jsonb_build_object(
    'classes', coalesce((
      select jsonb_agg(jsonb_build_object(
        'title', series.title,
        'branch_name', branch.name,
        'starts_at', session.starts_at,
        'capacity', series.capacity,
        'booked_count', (
          select count(*) from public.bookings booking
          where booking.class_session_id = session.id
            and booking.status in ('booked', 'attended', 'no_show')
        )
      ) order by session.starts_at)
      from public.class_sessions session
      join public.class_series series on series.id = session.series_id
      join public.branches branch on branch.id = series.branch_id
      where session.status = 'scheduled'
        and session.starts_at >= start_of_day
        and session.starts_at < end_of_day
    ), '[]'::jsonb),
    'no_shows', coalesce((
      select jsonb_agg(jsonb_build_object(
        'member_name', coalesce(profile.display_name, 'Member'),
        'title', series.title,
        'branch_name', branch.name,
        'starts_at', session.starts_at
      ) order by session.starts_at)
      from public.bookings booking
      join public.class_sessions session on session.id = booking.class_session_id
      join public.class_series series on series.id = session.series_id
      join public.branches branch on branch.id = series.branch_id
      left join public.profiles profile on profile.id = booking.user_id
      where booking.status = 'no_show'
        and session.starts_at >= start_of_day
        and session.starts_at < end_of_day
    ), '[]'::jsonb),
    'ending_packages', coalesce((
      select jsonb_agg(jsonb_build_object(
        'member_name', coalesce(profile.display_name, 'Member'),
        'package_name', plan.name,
        'end_date', membership.end_date_exclusive - 1,
        'remaining_credits', membership.remaining_credits
      ) order by membership.end_date_exclusive, profile.display_name)
      from public.user_memberships membership
      join public.membership_plans plan on plan.id = membership.plan_id
      left join public.profiles profile on profile.id = membership.user_id
      where membership.status = 'active'
        and membership.end_date_exclusive > istanbul_today
        and membership.end_date_exclusive <= istanbul_today + 8
    ), '[]'::jsonb),
    'pending_payments', coalesce((
      select jsonb_agg(jsonb_build_object(
        'member_name', coalesce(profile.display_name, 'Member'),
        'package_name', plan.name,
        'price_minor', request.price_minor
      ) order by request.created_at)
      from public.membership_purchase_requests request
      join public.membership_plans plan on plan.id = request.plan_id
      left join public.profiles profile on profile.id = request.user_id
      where request.status = 'cash_payment_pending'
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.admin_today_operations() from public, anon, authenticated;
grant execute on function public.admin_today_operations() to authenticated;

commit;
