-- Private lessons are closed by default. Administrators can open the
-- member-facing feature without granting the client direct table writes.
begin;

create table if not exists public.studio_feature_settings (
  key text primary key,
  is_enabled boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

alter table public.studio_feature_settings enable row level security;
revoke all on public.studio_feature_settings from anon, authenticated;

insert into public.studio_feature_settings (key, is_enabled)
values ('private_lessons', false)
on conflict (key) do nothing;

create or replace function public.private_lesson_feature_enabled()
returns boolean language sql security definer set search_path = ''
stable
as $$
  select coalesce((
    select is_enabled
    from public.studio_feature_settings
    where key = 'private_lessons'
  ), false);
$$;

revoke all on function public.private_lesson_feature_enabled() from public, anon, authenticated;
grant execute on function public.private_lesson_feature_enabled() to authenticated;

create or replace function public.set_private_lesson_feature_enabled(enabled boolean)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not (select private.is_admin()) then
    raise exception 'Admin access required';
  end if;

  update public.studio_feature_settings
  set is_enabled = enabled, updated_at = now(), updated_by = (select auth.uid())
  where key = 'private_lessons';
end;
$$;

revoke all on function public.set_private_lesson_feature_enabled(boolean) from public, anon, authenticated;
grant execute on function public.set_private_lesson_feature_enabled(boolean) to authenticated;

-- Keep the feature boundary on the server as well as in the Flutter UI. These
-- definitions include the previously introduced 05:00–22:00 default closure.
create or replace function public.member_private_lesson_slots(target_date date)
returns table(starts_at timestamptz, status text)
language plpgsql security definer set search_path = ''
as $$
declare instructor_id uuid; slot_start timestamptz; local_hour integer;
declare istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if not (select private.is_approved_member()) then
    raise exception 'Approved member access required';
  end if;
  if not public.private_lesson_feature_enabled() then
    raise exception 'Private lesson requests are currently closed';
  end if;
  if target_date < istanbul_today or target_date > istanbul_today + 60 then
    raise exception 'Choose a date within the next 60 days';
  end if;
  select user_id into instructor_id from public.user_roles
    where role = 'admin' order by user_id limit 1;
  if instructor_id is null then raise exception 'No instructor is available'; end if;
  for slot_start in
    select ((target_date + make_time(hour_value, 0, 0)) at time zone 'Europe/Istanbul')
    from generate_series(0, 23) as hour_value
  loop
    local_hour := extract(hour from slot_start at time zone 'Europe/Istanbul');
    starts_at := slot_start;
    status := case
      when local_hour >= 22 or local_hour < 5 then 'default_closed'
      when slot_start <= now() then 'unavailable'
      when exists (select 1 from public.private_lesson_blocks block
        where block.instructor_user_id = instructor_id
          and block.starts_at < slot_start + interval '1 hour'
          and block.ends_at > slot_start) then 'unavailable'
      when exists (select 1 from public.private_lesson_requests request
        where request.instructor_user_id = instructor_id
          and request.status in ('pending', 'approved')
          and request.starts_at < slot_start + interval '1 hour'
          and request.ends_at > slot_start) then 'unavailable'
      else 'available'
    end;
    return next;
  end loop;
end;
$$;

create or replace function public.request_private_lesson(target_starts_at timestamptz)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare instructor_id uuid; request_id uuid; local_start timestamp;
begin
  if not (select private.is_approved_member()) then
    raise exception 'Approved member access required';
  end if;
  if not public.private_lesson_feature_enabled() then
    raise exception 'Private lesson requests are currently closed';
  end if;
  local_start := target_starts_at at time zone 'Europe/Istanbul';
  if date_trunc('hour', local_start) <> local_start or target_starts_at <= now() then
    raise exception 'Choose an available one-hour slot';
  end if;
  if extract(hour from local_start) >= 22 or extract(hour from local_start) < 5 then
    raise exception 'Private lesson reservations are closed between 22:00 and 05:00';
  end if;
  select user_id into instructor_id from public.user_roles
    where role = 'admin' order by user_id limit 1;
  if instructor_id is null then raise exception 'No instructor is available'; end if;
  perform pg_advisory_xact_lock(hashtext(instructor_id::text));
  if exists (select 1 from public.private_lesson_blocks block
      where block.instructor_user_id = instructor_id
        and block.starts_at < target_starts_at + interval '1 hour'
        and block.ends_at > target_starts_at)
    or exists (select 1 from public.private_lesson_requests request
      where request.instructor_user_id = instructor_id
        and request.status in ('pending', 'approved')
        and request.starts_at < target_starts_at + interval '1 hour'
        and request.ends_at > target_starts_at) then
    raise exception 'This time is no longer available';
  end if;
  insert into public.private_lesson_requests(member_user_id, instructor_user_id, starts_at, ends_at)
  values ((select auth.uid()), instructor_id, target_starts_at, target_starts_at + interval '1 hour')
  returning id into request_id;
  return request_id;
end;
$$;

commit;
