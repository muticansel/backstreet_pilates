-- A fixed package becomes immutable when its first class begins.
begin;

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
  select * into series_record
  from public.class_series
  where offer_id = admin_update_fixed_offer.target_offer_id
    and is_active
  for update;
  if not found then raise exception 'Fixed package was not found'; end if;
  if exists (
    select 1 from public.class_sessions session
    where session.series_id = series_record.id and session.starts_at <= now()
  ) then
    raise exception 'A package cannot be edited after its first class has started';
  end if;
  select offer.plan_id into plan_id
  from public.branch_offers offer
  where offer.id = admin_update_fixed_offer.target_offer_id;
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
    and membership.purchase_request_id in (
      select id from public.membership_purchase_requests
      where offer_id = admin_update_fixed_offer.target_offer_id
    );
end;
$$;
revoke all on function public.admin_update_fixed_offer(uuid, text, bigint, integer, integer[], time[]) from public, anon, authenticated;
grant execute on function public.admin_update_fixed_offer(uuid, text, bigint, integer, integer[], time[]) to authenticated;

commit;
