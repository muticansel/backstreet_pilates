-- Admin-created fixed packages, automatic capacity holds and bookings.
begin;

create table public.class_series (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid not null unique references public.branch_offers(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  title text not null check (length(trim(title)) > 0),
  capacity integer not null check (capacity between 1 and 6),
  starts_on date not null,
  duration_minutes integer not null default 50 check (duration_minutes between 15 and 180),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.class_series_slots (
  series_id uuid not null references public.class_series(id) on delete cascade,
  weekday integer not null check (weekday between 1 and 7),
  starts_at time not null,
  primary key (series_id, weekday)
);
create table public.class_sessions (
  id uuid primary key default gen_random_uuid(),
  series_id uuid not null references public.class_series(id) on delete restrict,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled', 'cancelled', 'completed')),
  check (ends_at > starts_at), unique (series_id, starts_at)
);
create index class_sessions_series_upcoming_idx on public.class_sessions(series_id, starts_at) where status = 'scheduled';
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  membership_id uuid not null references public.user_memberships(id) on delete restrict,
  class_session_id uuid not null references public.class_sessions(id) on delete restrict,
  status text not null default 'booked' check (status in ('booked', 'cancelled', 'attended', 'no_show')),
  booked_at timestamptz not null default now(), cancelled_at timestamptz,
  check ((status = 'cancelled') = (cancelled_at is not null)),
  unique (user_id, class_session_id)
);
create index bookings_member_upcoming_idx on public.bookings(user_id, class_session_id) where status = 'booked';
create table public.purchase_request_session_holds (
  request_id uuid not null references public.membership_purchase_requests(id) on delete cascade,
  class_session_id uuid not null references public.class_sessions(id) on delete restrict,
  primary key (request_id, class_session_id)
);
create index session_holds_session_idx on public.purchase_request_session_holds(class_session_id);

alter table public.class_series enable row level security;
alter table public.class_series_slots enable row level security;
alter table public.class_sessions enable row level security;
alter table public.bookings enable row level security;
alter table public.purchase_request_session_holds enable row level security;
revoke all on public.class_series, public.class_series_slots, public.class_sessions, public.bookings, public.purchase_request_session_holds from anon, authenticated;
grant select on public.class_series, public.class_series_slots, public.class_sessions, public.bookings to authenticated;
create policy class_series_read on public.class_series for select to authenticated using (is_active or (select private.is_admin()));
create policy class_slots_read on public.class_series_slots for select to authenticated using (true);
create policy sessions_read on public.class_sessions for select to authenticated using (status = 'scheduled' or (select private.is_admin()));
create policy own_bookings_read on public.bookings for select to authenticated using (user_id = (select auth.uid()) or (select private.is_admin()));

create function public.admin_create_fixed_offer(
  target_name text, target_branch_id uuid, target_price_minor bigint,
  target_capacity integer, target_total_credits integer, target_sessions_per_week integer,
  target_starts_on date, target_weekdays integer[], target_start_times time[]
)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare branch_code text; branch_limit integer; duration_weeks integer;
declare plan_id uuid; offer_id uuid; new_series_id uuid; selected_count integer;
declare istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  if trim(target_name) = '' then raise exception 'Package name is required'; end if;
  if target_price_minor < 0 then raise exception 'Price cannot be negative'; end if;
  if target_total_credits < 1 or target_sessions_per_week < 1 then raise exception 'Class counts must be positive'; end if;
  if mod(target_total_credits, target_sessions_per_week) <> 0 then raise exception 'Total classes must divide evenly by weekly classes'; end if;
  if target_starts_on < istanbul_today then raise exception 'First class date cannot be in the past'; end if;
  if coalesce(cardinality(target_weekdays), 0) <> target_sessions_per_week
    or coalesce(cardinality(target_start_times), 0) <> target_sessions_per_week then
    raise exception 'Choose one weekday and time for each weekly class';
  end if;
  if exists (select 1 from unnest(target_weekdays) weekday group by weekday having count(*) > 1 or weekday not between 1 and 7) then
    raise exception 'Weekdays must be unique and between Monday and Sunday';
  end if;
  if extract(isodow from target_starts_on)::integer <> all(target_weekdays) then
    raise exception 'First class date must match one of the selected weekdays';
  end if;
  select code into branch_code from public.branches where id = target_branch_id and is_active;
  if not found then raise exception 'Selected branch is not available'; end if;
  branch_limit := case branch_code when 'oran' then 3 when 'incek' then 6 end;
  if target_capacity < 1 or target_capacity > branch_limit then raise exception 'Capacity exceeds the branch limit of %', branch_limit; end if;
  duration_weeks := target_total_credits / target_sessions_per_week;
  insert into public.membership_plans(code, name, total_credits, sessions_per_week, duration_weeks, scheduling_mode, is_active)
    values ('fixed_' || gen_random_uuid(), trim(target_name), target_total_credits, target_sessions_per_week, duration_weeks, 'fixed', true) returning id into plan_id;
  insert into public.branch_offers(branch_id, plan_id, price_minor, currency, is_active)
    values (target_branch_id, plan_id, target_price_minor, 'TRY', true) returning id into offer_id;
  insert into public.class_series(offer_id, branch_id, title, capacity, starts_on)
    values (offer_id, target_branch_id, trim(target_name), target_capacity, target_starts_on) returning id into new_series_id;
  insert into public.class_series_slots(series_id, weekday, starts_at)
    select new_series_id, target_weekdays[index], target_start_times[index]
    from generate_subscripts(target_weekdays, 1) index;
  insert into public.class_sessions(series_id, starts_at, ends_at)
    select new_series_id,
      ((day_value::date + slot.starts_at) at time zone 'Europe/Istanbul'),
      ((day_value::date + slot.starts_at + interval '50 minutes') at time zone 'Europe/Istanbul')
    from generate_series(
      target_starts_on,
      target_starts_on + (duration_weeks * 7) + 6,
      interval '1 day'
    ) as generated(day_value)
    join public.class_series_slots slot
      on slot.series_id = new_series_id
      and extract(isodow from generated.day_value)::integer = slot.weekday
    order by generated.day_value, slot.starts_at
    limit target_total_credits;
  select count(*) into selected_count from public.class_sessions session where session.series_id = new_series_id;
  if selected_count <> target_total_credits then raise exception 'The generated schedule does not match the total class count'; end if;
  return offer_id;
end;
$$;
revoke all on function public.admin_create_fixed_offer(text, uuid, bigint, integer, integer, integer, date, integer[], time[]) from public, anon, authenticated;
grant execute on function public.admin_create_fixed_offer(text, uuid, bigint, integer, integer, integer, date, integer[], time[]) to authenticated;

create function public.admin_delete_fixed_offer(target_offer_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  update public.branch_offers set is_active = false
    where id = target_offer_id
      and exists (select 1 from public.class_series where offer_id = target_offer_id);
  if not found then raise exception 'Fixed package was not found'; end if;
  update public.membership_plans set is_active = false where id = (select plan_id from public.branch_offers where id = target_offer_id);
  update public.class_series set is_active = false where offer_id = target_offer_id;
end;
$$;
revoke all on function public.admin_delete_fixed_offer(uuid) from public, anon, authenticated;
grant execute on function public.admin_delete_fixed_offer(uuid) to authenticated;

create or replace function public.request_cash_membership_purchase(target_offer_id uuid, target_requested_start_date date)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare offer_record record; session_record record; request_id uuid; selected_sessions integer := 0; occupied_seats integer;
declare istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if (select auth.uid()) is null then raise exception 'Sign in required'; end if;
  if target_requested_start_date < istanbul_today then raise exception 'Requested start date cannot be in the past'; end if;
  select o.id, o.branch_id, o.plan_id, o.price_minor, o.currency,
    p.total_credits, p.sessions_per_week, p.duration_weeks,
    series.id series_id, series.starts_on
    into offer_record from public.branch_offers o join public.membership_plans p on p.id = o.plan_id
    join public.class_series series on series.offer_id = o.id
    where o.id = target_offer_id and o.is_active and p.is_active and series.is_active;
  if not found then raise exception 'This package is not available'; end if;
  if exists (select 1 from public.membership_purchase_requests request where request.user_id = (select auth.uid()) and request.offer_id = offer_record.id and request.status = 'cash_payment_pending') then raise exception 'You already have a pending request for this package'; end if;
  for session_record in select id from public.class_sessions where series_id = offer_record.series_id and status = 'scheduled' and starts_at > now() order by starts_at for update loop
    selected_sessions := selected_sessions + 1;
    select count(*) into occupied_seats from public.bookings booking where booking.class_session_id = session_record.id and booking.status in ('booked', 'attended', 'no_show');
    occupied_seats := occupied_seats + (select count(*) from public.purchase_request_session_holds hold join public.membership_purchase_requests request on request.id = hold.request_id where hold.class_session_id = session_record.id and request.status = 'cash_payment_pending');
    if occupied_seats >= (select capacity from public.class_series where id = offer_record.series_id) then raise exception 'This class series is full'; end if;
  end loop;
  if selected_sessions <> offer_record.total_credits then raise exception 'The class schedule is incomplete or has started'; end if;
  insert into public.membership_purchase_requests(user_id, offer_id, branch_id, plan_id, requested_start_date, payment_method, status, price_minor, currency, total_credits, sessions_per_week, duration_weeks)
    values ((select auth.uid()), offer_record.id, offer_record.branch_id, offer_record.plan_id, offer_record.starts_on, 'cash', 'cash_payment_pending', offer_record.price_minor, offer_record.currency, offer_record.total_credits, offer_record.sessions_per_week, offer_record.duration_weeks) returning id into request_id;
  insert into public.purchase_request_session_holds(request_id, class_session_id) select request_id, id from public.class_sessions where series_id = offer_record.series_id and status = 'scheduled' and starts_at > now();
  return request_id;
end;
$$;

create or replace function public.confirm_cash_membership_purchase(target_request_id uuid)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare request_record public.membership_purchase_requests%rowtype; membership_id uuid; first_session_date date; hold_count integer; istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  select * into request_record from public.membership_purchase_requests where id = target_request_id and status = 'cash_payment_pending' for update;
  if not found then raise exception 'Cash request is not pending'; end if;
  select count(*), min((session.starts_at at time zone 'Europe/Istanbul')::date) into hold_count, first_session_date from public.purchase_request_session_holds hold join public.class_sessions session on session.id = hold.class_session_id where hold.request_id = request_record.id;
  if hold_count <> request_record.total_credits then raise exception 'The held class schedule is incomplete'; end if;
  update public.membership_purchase_requests set status = 'cash_payment_confirmed', confirmed_at = now(), confirmed_by = (select auth.uid()) where id = request_record.id;
  insert into public.user_memberships(user_id, branch_id, plan_id, purchase_request_id, status, requested_start_date, effective_start_date, end_date_exclusive, total_credits, remaining_credits, activated_at)
    values (request_record.user_id, request_record.branch_id, request_record.plan_id, request_record.id, case when first_session_date <= istanbul_today then 'active' else 'pending_start' end, request_record.requested_start_date, first_session_date, first_session_date + (request_record.duration_weeks * 7), request_record.total_credits, 0, case when first_session_date <= istanbul_today then now() else null end) returning id into membership_id;
  insert into public.bookings(user_id, membership_id, class_session_id) select request_record.user_id, membership_id, class_session_id from public.purchase_request_session_holds where request_id = request_record.id;
  delete from public.purchase_request_session_holds where request_id = request_record.id;
  return membership_id;
end;
$$;
revoke all on function public.request_cash_membership_purchase(uuid, date) from public, anon, authenticated;
grant execute on function public.request_cash_membership_purchase(uuid, date) to authenticated;
revoke all on function public.confirm_cash_membership_purchase(uuid) from public, anon, authenticated;
grant execute on function public.confirm_cash_membership_purchase(uuid) to authenticated;
commit;
