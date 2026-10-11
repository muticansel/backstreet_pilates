-- Run on a development project after the fixed-series migrations.
-- The transaction creates an admin and package fixture, then rolls both back.
begin;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '00000000-0000-4000-8000-000000000010',
  'authenticated', 'authenticated', 'fixed-offer-test@example.invalid', '', now(),
  '{"provider":"email","providers":["email"]}',
  '{"first_name":"Fixed","last_name":"Offer","display_name":"Fixed Offer"}',
  now(), now()
);
update public.user_roles set role = 'admin'
where user_id = '00000000-0000-4000-8000-000000000010';

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000010', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000010","role":"authenticated"}', true);

do $$
declare offer_id uuid; branch_id uuid;
declare first_class_day date := (now() at time zone 'Europe/Istanbul')::date + 7;
declare weekday integer;
begin
  select id into branch_id from public.branches where code = 'oran';
  weekday := extract(isodow from first_class_day)::integer;
  offer_id := public.admin_create_fixed_offer(
    'Editing check', branch_id, 500000, 3, 2, 1, first_class_day,
    array[weekday], array['09:00'::time]
  );
  perform public.admin_update_fixed_offer(
    offer_id, 'Editing check updated', 510000, 3, array[weekday], array['10:00'::time]
  );
  if not exists (
    select 1 from public.membership_plans plan
    join public.branch_offers offer on offer.plan_id = plan.id
    where offer.id = offer_id and plan.name = 'Editing check updated'
  ) then
    raise exception 'Future fixed offer update was not saved';
  end if;
  perform set_config('fixed_offer_editing_check.offer_id', offer_id::text, true);
  perform set_config('fixed_offer_editing_check.weekday', weekday::text, true);
end;
$$;

reset role;
update public.class_sessions
set starts_at = now() - interval '1 minute', ends_at = now() + interval '49 minutes'
where series_id = (
  select id from public.class_series
  where offer_id = current_setting('fixed_offer_editing_check.offer_id')::uuid
)
and starts_at = (
  select min(starts_at) from public.class_sessions
  where series_id = (
    select id from public.class_series
    where offer_id = current_setting('fixed_offer_editing_check.offer_id')::uuid
  )
);

set local role authenticated;
do $$
begin
  begin
    perform public.admin_update_fixed_offer(
      current_setting('fixed_offer_editing_check.offer_id')::uuid,
      'Blocked update', 520000, 3,
      array[current_setting('fixed_offer_editing_check.weekday')::integer],
      array['11:00'::time]
    );
    raise exception 'Started fixed offer update was allowed';
  exception when raise_exception then
    if sqlerrm <> 'A package cannot be edited after its first class has started' then
      raise;
    end if;
  end;
end;
$$;

rollback;
