-- Do not let a member request an overlapping copy of a package they already own.
-- The server remains authoritative when requests come from another device.
begin;

create or replace function public.request_cash_membership_purchase(
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

  if exists (
    select 1 from public.membership_purchase_requests request
    where request.user_id = (select auth.uid())
      and request.offer_id = offer_record.id
      and request.status = 'cash_payment_pending'
  ) then
    raise exception 'You already have a pending request for this package';
  end if;

  if exists (
    select 1 from public.user_memberships membership
    where membership.user_id = (select auth.uid())
      and membership.branch_id = offer_record.branch_id
      and membership.plan_id = offer_record.plan_id
      and membership.status in ('active', 'pending_start')
      and membership.end_date_exclusive > target_requested_start_date
  ) then
    raise exception 'You already have this package. You can request it again after your current package ends';
  end if;

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

commit;
