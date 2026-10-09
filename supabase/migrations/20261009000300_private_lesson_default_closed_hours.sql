-- Enforce the default closed period on the server and return it to the app as
-- visibly locked slots. Run after 20261009000100_private_lesson_calendar.sql.
begin;

create or replace function public.member_private_lesson_slots(target_date date)
returns table(starts_at timestamptz, status text)
language plpgsql security definer set search_path = ''
as $$
declare instructor_id uuid; slot_start timestamptz; local_hour integer;
declare istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if not (select private.is_approved_member()) then raise exception 'Approved member access required'; end if;
  if target_date < istanbul_today or target_date > istanbul_today + 60 then raise exception 'Choose a date within the next 60 days'; end if;
  select user_id into instructor_id from public.user_roles where role = 'admin' order by user_id limit 1;
  if instructor_id is null then raise exception 'No instructor is available'; end if;
  for slot_start in select ((target_date + make_time(hour_value, 0, 0)) at time zone 'Europe/Istanbul') from generate_series(0, 23) as hour_value loop
    local_hour := extract(hour from slot_start at time zone 'Europe/Istanbul');
    starts_at := slot_start;
    status := case
      when local_hour >= 22 or local_hour < 5 then 'default_closed'
      when slot_start <= now() then 'unavailable'
      when exists (select 1 from public.private_lesson_blocks block where block.instructor_user_id = instructor_id and block.starts_at < slot_start + interval '1 hour' and block.ends_at > slot_start) then 'unavailable'
      when exists (select 1 from public.private_lesson_requests request where request.instructor_user_id = instructor_id and request.status in ('pending', 'approved') and request.starts_at < slot_start + interval '1 hour' and request.ends_at > slot_start) then 'unavailable'
      else 'available' end;
    return next;
  end loop;
end;
$$;

create or replace function public.request_private_lesson(target_starts_at timestamptz)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare instructor_id uuid; request_id uuid; local_start timestamp;
begin
  if not (select private.is_approved_member()) then raise exception 'Approved member access required'; end if;
  local_start := target_starts_at at time zone 'Europe/Istanbul';
  if date_trunc('hour', local_start) <> local_start or target_starts_at <= now() then raise exception 'Choose an available one-hour slot'; end if;
  if extract(hour from local_start) >= 22 or extract(hour from local_start) < 5 then raise exception 'Private lesson reservations are closed between 22:00 and 05:00'; end if;
  select user_id into instructor_id from public.user_roles where role = 'admin' order by user_id limit 1;
  if instructor_id is null then raise exception 'No instructor is available'; end if;
  perform pg_advisory_xact_lock(hashtext(instructor_id::text));
  if exists (select 1 from public.private_lesson_blocks block where block.instructor_user_id = instructor_id and block.starts_at < target_starts_at + interval '1 hour' and block.ends_at > target_starts_at)
    or exists (select 1 from public.private_lesson_requests request where request.instructor_user_id = instructor_id and request.status in ('pending', 'approved') and request.starts_at < target_starts_at + interval '1 hour' and request.ends_at > target_starts_at) then raise exception 'This time is no longer available'; end if;
  insert into public.private_lesson_requests(member_user_id, instructor_user_id, starts_at, ends_at) values ((select auth.uid()), instructor_id, target_starts_at, target_starts_at + interval '1 hour') returning id into request_id;
  return request_id;
end;
$$;
commit;
