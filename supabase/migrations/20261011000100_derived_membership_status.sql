-- The package badge must follow its dated bookings, not a stale stored status.
begin;

create or replace function public.member_approved_packages()
returns table(
  id uuid, status text, total_credits integer, remaining_credits integer,
  effective_start_date date, end_date_exclusive date, branch_name text,
  plan_name text
) language sql stable security definer set search_path = ''
as $$
  select membership.id,
    case
      when membership.status = 'active'
        and (coalesce(summary.remaining_credits, membership.remaining_credits) = 0
          or coalesce(summary.end_date_exclusive, membership.end_date_exclusive)
             <= (now() at time zone 'Europe/Istanbul')::date)
        then 'expired'
      else membership.status
    end,
    membership.total_credits,
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

-- Bring already-finished fixed packages into line for admin counts and reports.
update public.user_memberships membership
set status = 'expired'
where membership.status = 'active'
  and exists (
    select 1
    from public.membership_schedule_summary(membership.id) summary
    where summary.remaining_credits = 0
       or summary.end_date_exclusive <= (now() at time zone 'Europe/Istanbul')::date
  );

notify pgrst, 'reload schema';
commit;
