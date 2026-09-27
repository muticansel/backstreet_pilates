-- Foundation only: profiles, roles, branches, plans and branch prices.
-- Reservations, purchases, payment processing and cancellation rules come later.
begin;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  phone text,
  created_at timestamptz not null default now()
);
create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('member', 'admin'))
);
create table public.branches (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code in ('oran', 'incek')),
  name text not null check (length(trim(name)) > 0),
  timezone text not null default 'Europe/Istanbul'
    check (timezone = 'Europe/Istanbul'),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.membership_plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null check (length(trim(name)) > 0),
  total_credits integer not null check (total_credits > 0),
  sessions_per_week integer not null check (sessions_per_week between 1 and 7),
  duration_weeks integer not null check (duration_weeks > 0),
  scheduling_mode text not null default 'fixed'
    check (scheduling_mode in ('fixed', 'flexible')),
  is_active boolean not null default false,
  created_at timestamptz not null default now()
);
create table public.branch_offers (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete restrict,
  plan_id uuid not null references public.membership_plans(id) on delete restrict,
  price_minor bigint not null check (price_minor >= 0),
  currency text not null default 'TRY' check (currency = 'TRY'),
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  unique (branch_id, plan_id)
);
create index branch_offers_plan_id_idx on public.branch_offers(plan_id);

-- Role claims from user-editable signup metadata are deliberately ignored.
create function private.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = (select auth.uid()) and role = 'admin'
  );
$$;
revoke all on function private.is_admin() from public, anon, authenticated;
grant execute on function private.is_admin() to authenticated;

create function private.create_user_profile()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles(id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', ''));
  insert into public.user_roles(user_id, role) values (new.id, 'member');
  return new;
end;
$$;
revoke all on function private.create_user_profile() from public, anon, authenticated;
create trigger on_auth_user_created
  after insert on auth.users for each row
  execute function private.create_user_profile();

-- Handle accounts created before this migration without changing existing roles.
insert into public.profiles(id, display_name)
select id, coalesce(raw_user_meta_data ->> 'display_name', '') from auth.users
on conflict (id) do nothing;
insert into public.user_roles(user_id, role)
select id, 'member' from auth.users on conflict (user_id) do nothing;

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.branches enable row level security;
alter table public.membership_plans enable row level security;
alter table public.branch_offers enable row level security;

revoke all on public.profiles, public.user_roles, public.branches,
  public.membership_plans, public.branch_offers from anon, authenticated;
grant select on public.profiles, public.user_roles, public.branches,
  public.membership_plans, public.branch_offers to authenticated;
grant update (display_name, phone) on public.profiles to authenticated;
grant insert, update, delete on public.branches, public.membership_plans,
  public.branch_offers to authenticated;

create policy profiles_read on public.profiles for select to authenticated
using (id = (select auth.uid()) or (select private.is_admin()));
create policy profiles_edit on public.profiles for update to authenticated
using (id = (select auth.uid()) or (select private.is_admin()))
with check (id = (select auth.uid()) or (select private.is_admin()));
create policy roles_read on public.user_roles for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_admin()));
-- No client write privileges or policies for user_roles, even for app admins.

create policy branches_read on public.branches for select to authenticated
using (is_active or (select private.is_admin()));
create policy branches_admin on public.branches for all to authenticated
using ((select private.is_admin())) with check ((select private.is_admin()));
create policy plans_read on public.membership_plans for select to authenticated
using (is_active or (select private.is_admin()));
create policy plans_admin on public.membership_plans for all to authenticated
using ((select private.is_admin())) with check ((select private.is_admin()));
create policy offers_read on public.branch_offers for select to authenticated
using ((select private.is_admin()) or (
  is_active
  and exists (select 1 from public.branches b where b.id = branch_id and b.is_active)
  and exists (select 1 from public.membership_plans p where p.id = plan_id and p.is_active)
));
create policy offers_admin on public.branch_offers for all to authenticated
using ((select private.is_admin())) with check ((select private.is_admin()));

comment on table public.branch_offers is
  'Catalog only. Future purchases must snapshot price, schedule and policy; this table is not a purchase record.';
commit;
