-- First approved sale offer: İncek, 8 classes, twice weekly, 4 weeks, 5,000 TRY.
begin;

do $$ begin
  update public.membership_plans
  set name = '8 ders / haftada 2 / 4 hafta', is_active = true
  where code = 'demo-8-2-4';
  if not found then
    raise exception 'Expected plan demo-8-2-4 is missing';
  end if;

  update public.branch_offers offer
  set price_minor = 500000, currency = 'TRY', is_active = true
  from public.branches branch
  join public.membership_plans plan on plan.code = 'demo-8-2-4'
  where offer.branch_id = branch.id
    and offer.plan_id = plan.id
    and branch.code = 'incek';
  if not found then
    raise exception 'Expected İncek offer for demo-8-2-4 is missing';
  end if;
end $$;

commit;
