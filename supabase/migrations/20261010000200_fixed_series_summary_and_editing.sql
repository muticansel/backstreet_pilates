-- Fixed-series membership summaries are derived from dated bookings.
begin;

create or replace function public.membership_schedule_summary(target_membership_id uuid)
returns table(remaining_credits integer, end_date_exclusive date)
language sql stable security definer set search_path = ''
as $$
  select
    count(*) filter (
      where booking.status = 'booked' and session.starts_at > now()
    )::integer as remaining_credits,
    (max((session.starts_at at time zone 'Europe/Istanbul')::date) + 1)::date
      as end_date_exclusive
  from public.bookings booking
  join public.class_sessions session on session.id = booking.class_session_id
  where booking.membership_id = target_membership_id
    and booking.status in ('booked', 'attended', 'no_show');
$$;

-- Correct legacy records, including records created while fixed-series
-- memberships were initialized with zero remaining credits.
update public.user_memberships membership
set remaining_credits = (select summary.remaining_credits from public.membership_schedule_summary(membership.id) summary),
    end_date_exclusive = coalesce((select summary.end_date_exclusive from public.membership_schedule_summary(membership.id) summary), membership.end_date_exclusive)
where exists (select 1 from public.bookings booking where booking.membership_id = membership.id);

create or replace function public.member_approved_packages()
returns table(
  id uuid, status text, total_credits integer, remaining_credits integer,
  effective_start_date date, end_date_exclusive date, branch_name text,
  plan_name text
) language sql stable security definer set search_path = ''
as $$
  select membership.id, membership.status, membership.total_credits,
    coalesce(summary.remaining_credits, membership.remaining_credits),
    membership.effective_start_date,
    coalesce(summary.end_date_exclusive, membership.end_date_exclusive),
    branch.name, plan.name
  from public.user_memberships membership
  join public.branches branch on branch.id = membership.branch_id
  join public.membership_plans plan on plan.id = membership.plan_id
  left join lateral public.membership_schedule_summary(membership.id) summary on true
  where membership.user_id = (select auth.uid()) or (select private.is_admin())
  order by membership.effective_start_date desc;
$$;
revoke all on function public.member_approved_packages() from public, anon, authenticated;
grant execute on function public.member_approved_packages() to authenticated;

create or replace function public.admin_monthly_group_class_income(target_month date)
returns bigint language sql stable security definer set search_path = ''
as $$
  with bounds as (
    select date_trunc('month', target_month)::date as starts_on,
      (date_trunc('month', target_month) + interval '1 month')::date as ends_on
  ), allocated as (
    select request.id,
      request.price_minor / request.total_credits as base_minor,
      request.price_minor % request.total_credits as remainder_minor,
      row_number() over (partition by request.id order by session.starts_at) as lesson_number,
      count(*) over (partition by request.id) as lesson_count,
      (session.starts_at at time zone 'Europe/Istanbul')::date as lesson_date
    from public.membership_purchase_requests request
    join public.user_memberships membership on membership.purchase_request_id = request.id
    join public.bookings booking on booking.membership_id = membership.id
    join public.class_sessions session on session.id = booking.class_session_id
    where request.status = 'cash_payment_confirmed'
      and booking.status in ('booked', 'attended', 'no_show')
  )
  select coalesce(sum(base_minor + case when lesson_number = lesson_count then remainder_minor else 0 end), 0)::bigint
  from allocated, bounds
  where lesson_date >= bounds.starts_on and lesson_date < bounds.ends_on;
$$;
revoke all on function public.admin_monthly_group_class_income(date) from public, anon, authenticated;
grant execute on function public.admin_monthly_group_class_income(date) to authenticated;

create or replace function public.admin_today_operations()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
  start_of_day timestamptz := (istanbul_today::timestamp at time zone 'Europe/Istanbul');
  end_of_day timestamptz := ((istanbul_today + 1)::timestamp at time zone 'Europe/Istanbul');
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  return jsonb_build_object(
    'classes', coalesce((select jsonb_agg(jsonb_build_object('title', series.title, 'branch_name', branch.name, 'starts_at', session.starts_at, 'capacity', series.capacity, 'booked_count', (select count(*) from public.bookings booking where booking.class_session_id = session.id and booking.status in ('booked', 'attended', 'no_show'))) order by session.starts_at) from public.class_sessions session join public.class_series series on series.id = session.series_id join public.branches branch on branch.id = series.branch_id where session.status = 'scheduled' and session.starts_at >= start_of_day and session.starts_at < end_of_day), '[]'::jsonb),
    'no_shows', coalesce((select jsonb_agg(jsonb_build_object('member_name', coalesce(profile.display_name, 'Member'), 'title', series.title, 'branch_name', branch.name, 'starts_at', session.starts_at) order by session.starts_at) from public.bookings booking join public.class_sessions session on session.id = booking.class_session_id join public.class_series series on series.id = session.series_id join public.branches branch on branch.id = series.branch_id left join public.profiles profile on profile.id = booking.user_id where booking.status = 'no_show' and session.starts_at >= start_of_day and session.starts_at < end_of_day), '[]'::jsonb),
    'ending_packages', coalesce((select jsonb_agg(jsonb_build_object('member_name', coalesce(profile.display_name, 'Member'), 'package_name', plan.name, 'end_date', summary.end_date_exclusive - 1, 'remaining_credits', summary.remaining_credits) order by summary.end_date_exclusive, profile.display_name) from public.user_memberships membership join public.membership_plans plan on plan.id = membership.plan_id left join public.profiles profile on profile.id = membership.user_id join lateral public.membership_schedule_summary(membership.id) summary on true where membership.status = 'active' and summary.end_date_exclusive > istanbul_today and summary.end_date_exclusive <= istanbul_today + 8), '[]'::jsonb),
    'pending_payments', coalesce((select jsonb_agg(jsonb_build_object('member_name', coalesce(profile.display_name, 'Member'), 'package_name', plan.name, 'price_minor', request.price_minor) order by request.created_at) from public.membership_purchase_requests request join public.membership_plans plan on plan.id = request.plan_id left join public.profiles profile on profile.id = request.user_id where request.status = 'cash_payment_pending'), '[]'::jsonb)
  );
end;
$$;

create or replace function public.admin_update_fixed_offer(
  target_offer_id uuid, target_name text, target_price_minor bigint,
  target_capacity integer, target_weekdays integer[], target_start_times time[]
) returns void language plpgsql security definer set search_path = ''
as $$
declare series_record public.class_series%rowtype; plan_id uuid; future_count integer;
declare booked_max integer; generated_count integer; start_day date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  if trim(target_name) = '' or target_price_minor < 0 or target_capacity < 1 then raise exception 'Invalid package details'; end if;
  if coalesce(cardinality(target_weekdays), 0) = 0 or cardinality(target_weekdays) <> cardinality(target_start_times) or exists (select 1 from unnest(target_weekdays) day_value group by day_value having count(*) > 1 or day_value not between 1 and 7) then raise exception 'Choose unique weekdays and times'; end if;
  select series into series_record from public.class_series series where series.offer_id = target_offer_id and series.is_active for update;
  if not found then raise exception 'Fixed package was not found'; end if;
  select offer.plan_id into plan_id from public.branch_offers offer where offer.id = target_offer_id;
  select count(*) into future_count from public.class_sessions where series_id = series_record.id and status = 'scheduled' and starts_at > now();
  select coalesce(max(occupied_count), 0) into booked_max from (
    select session.id,
      (select count(*) from public.bookings booking where booking.class_session_id = session.id and booking.status = 'booked') +
      (select count(*) from public.purchase_request_session_holds hold where hold.class_session_id = session.id) occupied_count
    from public.class_sessions session
    where session.series_id = series_record.id and session.starts_at > now()
  ) counts;
  if target_capacity < booked_max then raise exception 'Capacity cannot be lower than existing future reservations'; end if;
  create temporary table fixed_offer_old_sessions(id uuid primary key, position integer not null) on commit drop;
  create temporary table fixed_offer_replacements(old_id uuid primary key, new_id uuid not null) on commit drop;
  insert into fixed_offer_old_sessions(id, position)
  select id, row_number() over (order by starts_at)::integer
  from public.class_sessions
  where series_id = series_record.id and status = 'scheduled' and starts_at > now();
  -- Move the old future rows out of the unique `(series_id, starts_at)` range
  -- before inserting replacements; bookings and holds still point to them
  -- until the chronological remap below completes.
  update public.class_sessions session
  set starts_at = session.starts_at + interval '100 years',
      ends_at = session.ends_at + interval '100 years'
  where session.id in (select id from fixed_offer_old_sessions);
  insert into public.class_sessions(series_id, starts_at, ends_at)
  select series_record.id, ((day_value::date + target_start_times[index]) at time zone 'Europe/Istanbul'), ((day_value::date + target_start_times[index] + interval '50 minutes') at time zone 'Europe/Istanbul')
  from generate_series(start_day, start_day + (future_count * 7) + 7, interval '1 day') generated(day_value)
  join generate_subscripts(target_weekdays, 1) index on extract(isodow from generated.day_value)::integer = target_weekdays[index]
  where ((day_value::date + target_start_times[index]) at time zone 'Europe/Istanbul') > now()
  order by day_value, target_start_times[index]
  limit future_count;
  get diagnostics generated_count = row_count;
  if generated_count <> future_count then raise exception 'Could not generate the updated future schedule'; end if;
  insert into fixed_offer_replacements(old_id, new_id)
  select old.id, new.id
  from fixed_offer_old_sessions old
  join (
    select session.id, row_number() over (order by session.starts_at)::integer position
    from public.class_sessions session
    where session.series_id = series_record.id
      and session.status = 'scheduled'
      and session.starts_at > now()
      and not exists (select 1 from fixed_offer_old_sessions prior where prior.id = session.id)
  ) new on new.position = old.position;
  update public.bookings booking set class_session_id = replacement.new_id from fixed_offer_replacements replacement where booking.class_session_id = replacement.old_id;
  update public.purchase_request_session_holds hold set class_session_id = replacement.new_id from fixed_offer_replacements replacement where hold.class_session_id = replacement.old_id;
  delete from public.class_sessions session using fixed_offer_replacements replacement where session.id = replacement.old_id;
  update public.class_series set title = trim(target_name), capacity = target_capacity where id = series_record.id;
  delete from public.class_series_slots where series_id = series_record.id;
  insert into public.class_series_slots(series_id, weekday, starts_at)
  select series_record.id, target_weekdays[index], target_start_times[index]
  from generate_subscripts(target_weekdays, 1) index;
  update public.membership_plans set name = trim(target_name), sessions_per_week = cardinality(target_weekdays) where id = plan_id;
  update public.branch_offers set price_minor = target_price_minor where id = target_offer_id;
  update public.user_memberships membership
  set remaining_credits = (select summary.remaining_credits from public.membership_schedule_summary(membership.id) summary),
      end_date_exclusive = coalesce((select summary.end_date_exclusive from public.membership_schedule_summary(membership.id) summary), membership.end_date_exclusive)
  where exists (select 1 from public.bookings booking where booking.membership_id = membership.id)
    and membership.purchase_request_id in (select id from public.membership_purchase_requests where offer_id = target_offer_id);
end;
$$;
revoke all on function public.admin_update_fixed_offer(uuid, text, bigint, integer, integer[], time[]) from public, anon, authenticated;
grant execute on function public.admin_update_fixed_offer(uuid, text, bigint, integer, integer[], time[]) to authenticated;

commit;
