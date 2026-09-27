-- Run ONLY on the development project after migration + seed.
-- All fixtures and role changes are rolled back. Any assertion fails the script.
begin;
-- These are temporary project Auth users. The trigger under test creates their
-- profile and member role. The final ROLLBACK removes all of them.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-4000-8000-000000000001',
    'authenticated', 'authenticated', 'member-one@example.invalid', '', now(),
    '{"provider":"email","providers":["email"]}', '{"role":"admin"}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-4000-8000-000000000002',
    'authenticated', 'authenticated', 'member-two@example.invalid', '', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now()
  );

do $$ begin
  if (select role from public.user_roles where user_id = '00000000-0000-4000-8000-000000000001') <> 'member' then
    raise exception 'Signup metadata must not grant admin';
  end if;
  if (select count(*) from public.branches where code in ('oran', 'incek')) <> 2 then
    raise exception 'Branch seeds missing';
  end if;
  if (select count(*) from public.membership_plans where code like 'demo-%') <> 5 then
    raise exception 'Plan seeds missing';
  end if;
  if exists (select 1 from public.membership_plans where code like 'demo-%' and is_active) then
    raise exception 'Demo plans must be inactive';
  end if;
end $$;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
do $$ begin
  if (select count(*) from public.profiles) <> 1 then
    raise exception 'Member can read another profile';
  end if;
  if (select count(*) from public.branch_offers) <> 0 then
    raise exception 'Member can read inactive seed offers (use a fresh dev database)';
  end if;
  begin
    update public.user_roles set role = 'admin' where user_id = auth.uid();
    raise exception 'Member was allowed to change a role';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.membership_plans(code, name, total_credits, sessions_per_week, duration_weeks)
    values ('forbidden-member-plan', 'Forbidden', 8, 2, 4);
    raise exception 'Member was allowed to create a plan';
  exception when insufficient_privilege then null;
  end;
  update public.profiles set display_name = 'Own profile' where id = auth.uid();
  if not found then raise exception 'Own profile update failed'; end if;
  update public.profiles set display_name = 'Forbidden' where id = '00000000-0000-4000-8000-000000000002';
  if found then raise exception 'Another profile was modified'; end if;
end $$;

reset role;
update public.user_roles set role = 'admin' where user_id = '00000000-0000-4000-8000-000000000001';
set local role authenticated;
do $$ begin
  if (select count(*) from public.profiles where id in (
    '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002')) <> 2 then
    raise exception 'Admin cannot read both fixture profiles';
  end if;
  if (select count(*) from public.branch_offers o join public.membership_plans p on p.id = o.plan_id
      where p.code like 'demo-%') <> 10 then
    raise exception 'Admin cannot read offers for both branches';
  end if;
end $$;
reset role;
set local role anon;
do $$ begin
  begin
    perform 1 from public.profiles;
    raise exception 'Anonymous access to profiles was allowed';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
rollback;
