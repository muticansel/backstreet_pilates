-- New accounts must confirm their email and then be explicitly approved by an
-- administrator before they can use any member operation.
begin;

alter table public.profiles
  add column if not exists approval_status text not null default 'awaiting_email_confirmation'
    check (approval_status in ('awaiting_email_confirmation', 'pending_admin_approval', 'approved')),
  add column if not exists approved_at timestamptz,
  add column if not exists approved_by uuid references auth.users(id);

-- Do not lock existing active members when this migration is introduced.
update public.profiles
set approval_status = 'approved'
where approval_status = 'awaiting_email_confirmation' and is_active;

create index if not exists profiles_approval_queue_idx
  on public.profiles(approval_status, created_at);

create or replace function private.is_approved_member()
returns boolean language sql stable security definer set search_path = ''
as $$
  select (select private.is_admin()) or exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and is_active
      and approval_status = 'approved'
  );
$$;
revoke all on function private.is_approved_member() from public, anon, authenticated;
grant execute on function private.is_approved_member() to authenticated;

-- The profile is created at signup, before email verification. A confirmed
-- account becomes visible in the administrator queue exactly once.
create or replace function private.create_user_profile()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles(id, first_name, last_name, display_name, approval_status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name', ''),
    coalesce(new.raw_user_meta_data ->> 'display_name', ''),
    case when new.email_confirmed_at is null
      then 'awaiting_email_confirmation' else 'pending_admin_approval' end
  );
  insert into public.user_roles(user_id, role) values (new.id, 'member');
  return new;
end;
$$;

create or replace function private.queue_email_confirmed_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if old.email_confirmed_at is null and new.email_confirmed_at is not null then
    update public.profiles
    set approval_status = 'pending_admin_approval'
    where id = new.id and approval_status = 'awaiting_email_confirmation';
  end if;
  return new;
end;
$$;
revoke all on function private.queue_email_confirmed_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_email_confirmed on auth.users;
create trigger on_auth_user_email_confirmed
  after update of email_confirmed_at on auth.users for each row
  execute function private.queue_email_confirmed_user();

-- Pending accounts retain access only to their own profile, which the app uses
-- to render the home waiting screen. All member-facing data requires approval.
drop policy if exists branches_read on public.branches;
create policy branches_read on public.branches for select to authenticated
using ((select private.is_approved_member()) and is_active or (select private.is_admin()));
drop policy if exists plans_read on public.membership_plans;
create policy plans_read on public.membership_plans for select to authenticated
using ((select private.is_approved_member()) and is_active or (select private.is_admin()));
drop policy if exists offers_read on public.branch_offers;
create policy offers_read on public.branch_offers for select to authenticated
using ((select private.is_admin()) or ((select private.is_approved_member()) and is_active
  and exists (select 1 from public.branches b where b.id = branch_id and b.is_active)
  and exists (select 1 from public.membership_plans p where p.id = plan_id and p.is_active)));

-- Applied booking/purchase migrations use these policies when present.
do $$
begin
  if to_regclass('public.class_series') is not null then
    execute 'drop policy if exists class_series_read on public.class_series';
    execute 'create policy class_series_read on public.class_series for select to authenticated using ((select private.is_approved_member()) and is_active or (select private.is_admin()))';
  end if;
  if to_regclass('public.class_series_slots') is not null then
    execute 'drop policy if exists class_slots_read on public.class_series_slots';
    execute 'create policy class_slots_read on public.class_series_slots for select to authenticated using ((select private.is_approved_member()) or (select private.is_admin()))';
  end if;
  if to_regclass('public.class_sessions') is not null then
    execute 'drop policy if exists sessions_read on public.class_sessions';
    execute 'create policy sessions_read on public.class_sessions for select to authenticated using (((select private.is_approved_member()) and status = ''scheduled'') or (select private.is_admin()))';
  end if;
  if to_regclass('public.bookings') is not null then
    execute 'drop policy if exists own_bookings_read on public.bookings';
    execute 'create policy own_bookings_read on public.bookings for select to authenticated using ((user_id = (select auth.uid()) and (select private.is_approved_member())) or (select private.is_admin()))';
  end if;
  if to_regclass('public.membership_purchase_requests') is not null then
    execute 'drop policy if exists purchase_requests_read on public.membership_purchase_requests';
    execute 'create policy purchase_requests_read on public.membership_purchase_requests for select to authenticated using ((user_id = (select auth.uid()) and (select private.is_approved_member())) or (select private.is_admin()))';
  end if;
  if to_regclass('public.user_memberships') is not null then
    execute 'drop policy if exists memberships_read on public.user_memberships';
    execute 'create policy memberships_read on public.user_memberships for select to authenticated using ((user_id = (select auth.uid()) and (select private.is_approved_member())) or (select private.is_admin()))';
  end if;
end;
$$;

-- Purchase creation is a SECURITY DEFINER RPC, so it needs its own explicit
-- check in addition to RLS.
create or replace function public.request_cash_membership_purchase(target_offer_id uuid, target_requested_start_date date)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare offer_record record; session_record record; request_id uuid; selected_sessions integer := 0; occupied_seats integer;
declare istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if not (select private.is_approved_member()) then
    raise exception 'Account approval required';
  end if;
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

revoke all on function public.request_cash_membership_purchase(uuid, date) from public, anon, authenticated;
grant execute on function public.request_cash_membership_purchase(uuid, date) to authenticated;

commit;
