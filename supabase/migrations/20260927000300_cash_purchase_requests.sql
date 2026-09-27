-- Cash membership requests and admin confirmation.
begin;

create table public.membership_purchase_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  offer_id uuid not null references public.branch_offers(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  plan_id uuid not null references public.membership_plans(id) on delete restrict,
  requested_start_date date not null,
  payment_method text not null check (payment_method in ('cash', 'card')),
  status text not null check (status in (
    'cash_payment_pending', 'cash_payment_confirmed', 'cancelled'
  )),
  price_minor bigint not null check (price_minor >= 0),
  currency text not null check (currency = 'TRY'),
  total_credits integer not null check (total_credits > 0),
  sessions_per_week integer not null check (sessions_per_week between 1 and 7),
  duration_weeks integer not null check (duration_weeks > 0),
  confirmed_at timestamptz,
  confirmed_by uuid references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  check ((status = 'cash_payment_confirmed') = (confirmed_at is not null)),
  check ((status = 'cash_payment_confirmed') = (confirmed_by is not null))
);
create unique index one_pending_cash_request_per_offer_idx
  on public.membership_purchase_requests(user_id, offer_id)
  where status = 'cash_payment_pending';
create index membership_purchase_requests_admin_queue_idx
  on public.membership_purchase_requests(status, created_at desc);

create table public.user_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete restrict,
  branch_id uuid not null references public.branches(id) on delete restrict,
  plan_id uuid not null references public.membership_plans(id) on delete restrict,
  purchase_request_id uuid not null unique references public.membership_purchase_requests(id) on delete restrict,
  status text not null check (status in ('pending_start', 'active', 'expired', 'cancelled')),
  requested_start_date date not null,
  effective_start_date date not null,
  end_date_exclusive date not null,
  total_credits integer not null check (total_credits > 0),
  remaining_credits integer not null check (remaining_credits between 0 and total_credits),
  created_at timestamptz not null default now(),
  activated_at timestamptz,
  check (end_date_exclusive > effective_start_date)
);

create function public.request_cash_membership_purchase(
  target_offer_id uuid,
  target_requested_start_date date
)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  offer_record record;
  request_id uuid;
  istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if (select auth.uid()) is null then raise exception 'Sign in required'; end if;
  if target_requested_start_date < istanbul_today then
    raise exception 'Requested start date cannot be in the past';
  end if;
  select o.id, o.branch_id, o.plan_id, o.price_minor, o.currency,
    p.total_credits, p.sessions_per_week, p.duration_weeks
  into offer_record
  from public.branch_offers o
  join public.branches b on b.id = o.branch_id
  join public.membership_plans p on p.id = o.plan_id
  where o.id = target_offer_id and o.is_active and b.is_active and p.is_active;
  if not found then raise exception 'Selected package is not available'; end if;
  insert into public.membership_purchase_requests (
    user_id, offer_id, branch_id, plan_id, requested_start_date, payment_method,
    status, price_minor, currency, total_credits, sessions_per_week, duration_weeks
  ) values (
    (select auth.uid()), offer_record.id, offer_record.branch_id, offer_record.plan_id,
    target_requested_start_date, 'cash', 'cash_payment_pending', offer_record.price_minor,
    offer_record.currency, offer_record.total_credits, offer_record.sessions_per_week,
    offer_record.duration_weeks
  ) returning id into request_id;
  return request_id;
end;
$$;
revoke all on function public.request_cash_membership_purchase(uuid, date) from public, anon, authenticated;
grant execute on function public.request_cash_membership_purchase(uuid, date) to authenticated;

create function public.confirm_cash_membership_purchase(target_request_id uuid)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  request_record public.membership_purchase_requests%rowtype;
  membership_id uuid;
  istanbul_today date := (now() at time zone 'Europe/Istanbul')::date;
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  select * into request_record from public.membership_purchase_requests
    where id = target_request_id and status = 'cash_payment_pending' for update;
  if not found then raise exception 'Cash request is not pending'; end if;
  update public.membership_purchase_requests set status = 'cash_payment_confirmed',
    confirmed_at = now(), confirmed_by = (select auth.uid()) where id = target_request_id;
  insert into public.user_memberships (
    user_id, branch_id, plan_id, purchase_request_id, status, requested_start_date,
    effective_start_date, end_date_exclusive, total_credits, remaining_credits, activated_at
  ) values (
    request_record.user_id, request_record.branch_id, request_record.plan_id,
    request_record.id,
    case when request_record.requested_start_date <= istanbul_today then 'active' else 'pending_start' end,
    request_record.requested_start_date, request_record.requested_start_date,
    request_record.requested_start_date + (request_record.duration_weeks * 7),
    request_record.total_credits, request_record.total_credits,
    case when request_record.requested_start_date <= istanbul_today then now() else null end
  ) returning id into membership_id;
  return membership_id;
end;
$$;
revoke all on function public.confirm_cash_membership_purchase(uuid) from public, anon, authenticated;
grant execute on function public.confirm_cash_membership_purchase(uuid) to authenticated;

alter table public.membership_purchase_requests enable row level security;
alter table public.user_memberships enable row level security;
revoke all on public.membership_purchase_requests, public.user_memberships from anon, authenticated;
grant select on public.membership_purchase_requests, public.user_memberships to authenticated;
create policy purchase_requests_read on public.membership_purchase_requests for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_admin()));
create policy memberships_read on public.user_memberships for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_admin()));

comment on table public.membership_purchase_requests is
  'Cash requests are created and confirmed only by RPCs; card payments require a verified provider webhook.';
commit;
