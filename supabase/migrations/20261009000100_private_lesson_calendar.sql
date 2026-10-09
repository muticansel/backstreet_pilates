-- One-hour private lesson requests, instructor blackout periods and approval.
-- The first instructor is the active administrator. Times are presented in
-- Europe/Istanbul; all persisted instants remain timestamptz.
begin;

create table public.private_lesson_blocks (
  id uuid primary key default gen_random_uuid(),
  instructor_user_id uuid not null references auth.users(id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  check (ends_at > starts_at),
  check (date_trunc('hour', starts_at) = starts_at),
  check (date_trunc('hour', ends_at) = ends_at)
);
create index private_lesson_blocks_instructor_time_idx
  on public.private_lesson_blocks(instructor_user_id, starts_at, ends_at);

create table public.private_lesson_requests (
  id uuid primary key default gen_random_uuid(),
  member_user_id uuid not null references auth.users(id) on delete restrict,
  instructor_user_id uuid not null references auth.users(id) on delete restrict,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  requested_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id) on delete restrict,
  check (ends_at = starts_at + interval '1 hour'),
  check (date_trunc('hour', starts_at) = starts_at),
  check ((status in ('approved', 'rejected')) = (resolved_at is not null)),
  check ((status in ('approved', 'rejected')) = (resolved_by is not null))
);
create index private_lesson_requests_member_time_idx
  on public.private_lesson_requests(member_user_id, starts_at desc);
create index private_lesson_requests_instructor_time_idx
  on public.private_lesson_requests(instructor_user_id, starts_at)
  where status in ('pending', 'approved');

alter table public.private_lesson_blocks enable row level security;
alter table public.private_lesson_requests enable row level security;
revoke all on public.private_lesson_blocks, public.private_lesson_requests from anon, authenticated;
grant select on public.private_lesson_blocks, public.private_lesson_requests to authenticated;
create policy private_lesson_blocks_admin_read on public.private_lesson_blocks
  for select to authenticated using ((select private.is_admin()));
create policy private_lesson_requests_read on public.private_lesson_requests
  for select to authenticated using (
    member_user_id = (select auth.uid()) or (select private.is_admin())
  );

-- A private lesson is offered in whole one-hour slots from 07:00 through
-- 21:00. The end at 22:00 is intentionally exclusive. Administrators close
-- arbitrary ranges from their calendar; blocks and approved/pending requests
-- make the corresponding slot unavailable.
create function public.member_private_lesson_slots(target_date date)
returns table(starts_at timestamptz, status text)
language plpgsql security definer set search_path = ''
as $$
declare instructor_id uuid;
declare slot_start timestamptz;
declare slot_status text;
declare istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if not (select private.is_approved_member()) then
    raise exception 'Approved member access required';
  end if;
  if target_date < istanbul_today or target_date > istanbul_today + 60 then
    raise exception 'Choose a date within the next 60 days';
  end if;
  select user_id into instructor_id from public.user_roles
    where role = 'admin' order by user_id limit 1;
  if instructor_id is null then raise exception 'No instructor is available'; end if;
  for slot_start in
    select ((target_date + make_time(hour_value, 0, 0)) at time zone 'Europe/Istanbul')
    from generate_series(7, 21) as hour_value
  loop
    slot_status := case
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
    starts_at := slot_start;
    status := slot_status;
    return next;
  end loop;
end;
$$;
revoke all on function public.member_private_lesson_slots(date) from public, anon, authenticated;
grant execute on function public.member_private_lesson_slots(date) to authenticated;

create function public.request_private_lesson(target_starts_at timestamptz)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare instructor_id uuid; request_id uuid; local_start timestamp;
begin
  if not (select private.is_approved_member()) then
    raise exception 'Approved member access required';
  end if;
  local_start := target_starts_at at time zone 'Europe/Istanbul';
  if date_trunc('hour', local_start) <> local_start
    or extract(hour from local_start) not between 7 and 21
    or target_starts_at <= now() then
    raise exception 'Choose an available one-hour slot';
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
revoke all on function public.request_private_lesson(timestamptz) from public, anon, authenticated;
grant execute on function public.request_private_lesson(timestamptz) to authenticated;

create function public.admin_private_lesson_calendar(target_week_start date)
returns table(
  entry_type text, id uuid, starts_at timestamptz, ends_at timestamptz,
  status text, member_name text
)
language plpgsql security definer set search_path = ''
as $$
declare instructor_id uuid;
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  if extract(isodow from target_week_start) <> 1 then raise exception 'Week must start on Monday'; end if;
  instructor_id := (select auth.uid());
  return query
    select 'block', block.id, block.starts_at, block.ends_at, 'blocked', null::text
    from public.private_lesson_blocks block
    where block.instructor_user_id = instructor_id
      and block.starts_at < ((target_week_start + 7)::timestamp at time zone 'Europe/Istanbul')
      and block.ends_at > (target_week_start::timestamp at time zone 'Europe/Istanbul')
    union all
    select 'request', request.id, request.starts_at, request.ends_at, request.status,
      coalesce(profile.display_name, 'Member')
    from public.private_lesson_requests request
    join public.profiles profile on profile.id = request.member_user_id
    where request.instructor_user_id = instructor_id
      and request.starts_at < ((target_week_start + 7)::timestamp at time zone 'Europe/Istanbul')
      and request.ends_at > (target_week_start::timestamp at time zone 'Europe/Istanbul')
    order by 3;
end;
$$;
revoke all on function public.admin_private_lesson_calendar(date) from public, anon, authenticated;
grant execute on function public.admin_private_lesson_calendar(date) to authenticated;

create function public.admin_block_private_lesson_time(target_starts_at timestamptz, target_ends_at timestamptz)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare block_id uuid;
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  if target_starts_at < now() or target_ends_at <= target_starts_at
    or date_trunc('hour', target_starts_at) <> target_starts_at
    or date_trunc('hour', target_ends_at) <> target_ends_at then
    raise exception 'Choose a future whole-hour range';
  end if;
  perform pg_advisory_xact_lock(hashtext((select auth.uid())::text));
  if exists (select 1 from public.private_lesson_requests request
    where request.instructor_user_id = (select auth.uid()) and request.status = 'approved'
      and request.starts_at < target_ends_at and request.ends_at > target_starts_at) then
    raise exception 'An approved private lesson exists in this range';
  end if;
  insert into public.private_lesson_blocks(instructor_user_id, starts_at, ends_at, created_by)
    values ((select auth.uid()), target_starts_at, target_ends_at, (select auth.uid())) returning id into block_id;
  return block_id;
end;
$$;
revoke all on function public.admin_block_private_lesson_time(timestamptz, timestamptz) from public, anon, authenticated;
grant execute on function public.admin_block_private_lesson_time(timestamptz, timestamptz) to authenticated;

create function public.admin_resolve_private_lesson_request(target_request_id uuid, approve boolean)
returns void language plpgsql security definer set search_path = ''
as $$
declare request_record public.private_lesson_requests%rowtype;
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  perform pg_advisory_xact_lock(hashtext((select auth.uid())::text));
  select * into request_record from public.private_lesson_requests
    where id = target_request_id and instructor_user_id = (select auth.uid()) for update;
  if not found or request_record.status <> 'pending' then raise exception 'Private lesson request is no longer pending'; end if;
  if approve and (exists (select 1 from public.private_lesson_blocks block
      where block.instructor_user_id = (select auth.uid())
        and block.starts_at < request_record.ends_at and block.ends_at > request_record.starts_at)
    or exists (select 1 from public.private_lesson_requests other_request
      where other_request.instructor_user_id = (select auth.uid()) and other_request.status = 'approved'
        and other_request.id <> request_record.id
        and other_request.starts_at < request_record.ends_at and other_request.ends_at > request_record.starts_at)) then
    raise exception 'This time is no longer available';
  end if;
  update public.private_lesson_requests set
    status = case when approve then 'approved' else 'rejected' end,
    resolved_at = now(), resolved_by = (select auth.uid())
  where id = request_record.id;
end;
$$;
revoke all on function public.admin_resolve_private_lesson_request(uuid, boolean) from public, anon, authenticated;
grant execute on function public.admin_resolve_private_lesson_request(uuid, boolean) to authenticated;

-- Replaces every known notification check, including the early unnamed
-- notification_events_check left by the initial outbox migration.
alter table public.notification_events
  add column if not exists private_lesson_request_id uuid
    references public.private_lesson_requests(id) on delete cascade;
alter table public.notification_events
  drop constraint if exists notification_events_check,
  drop constraint if exists notification_events_event_type_check,
  drop constraint if exists notification_events_payload_check;
alter table public.notification_events add constraint notification_events_event_type_check
  check (event_type in ('cash_request_created', 'cash_request_confirmed', 'class_created',
    'registration_approval_requested', 'private_lesson_request_approved'));
alter table public.notification_events add constraint notification_events_payload_check check (
  (event_type = 'cash_request_created' and request_id is not null and class_series_id is null and registration_profile_id is null and private_lesson_request_id is null and payload = jsonb_build_object('action', 'cash_request', 'request_id', request_id))
  or (event_type = 'cash_request_confirmed' and request_id is not null and class_series_id is null and registration_profile_id is null and private_lesson_request_id is null and payload = jsonb_build_object('action', 'package_confirmed', 'request_id', request_id))
  or (event_type = 'class_created' and request_id is null and class_series_id is not null and registration_profile_id is null and private_lesson_request_id is null and payload = jsonb_build_object('action', 'class_created', 'class_series_id', class_series_id))
  or (event_type = 'registration_approval_requested' and request_id is null and class_series_id is null and registration_profile_id is not null and private_lesson_request_id is null and payload = jsonb_build_object('action', 'registration_pending', 'registration_profile_id', registration_profile_id))
  or (event_type = 'private_lesson_request_approved' and request_id is null and class_series_id is null and registration_profile_id is null and private_lesson_request_id is not null and payload = jsonb_build_object('action', 'private_lesson_approved', 'private_lesson_request_id', private_lesson_request_id))
);

create function private.enqueue_private_lesson_approval_notification()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if old.status = 'pending' and new.status = 'approved' then
    insert into public.notification_events(event_type, recipient_user_id, private_lesson_request_id, payload)
    values ('private_lesson_request_approved', new.member_user_id, new.id,
      jsonb_build_object('action', 'private_lesson_approved', 'private_lesson_request_id', new.id));
  end if;
  return new;
end;
$$;
revoke all on function private.enqueue_private_lesson_approval_notification() from public, anon, authenticated;
create trigger private_lesson_approval_notification
  after update of status on public.private_lesson_requests
  for each row execute function private.enqueue_private_lesson_approval_notification();

comment on table public.private_lesson_blocks is 'Administrator-created blackout ranges for one instructor calendar.';
comment on table public.private_lesson_requests is 'Member-requested one-hour private lessons. Only an admin approval reserves the instructor.';
commit;
