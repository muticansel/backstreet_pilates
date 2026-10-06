-- Admin-recorded individual lessons. Earnings are a percentage of the lesson fee.
begin;

create table public.individual_lesson_records (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references auth.users(id) on delete restrict,
  lesson_date date not null,
  lesson_price_minor bigint not null check (lesson_price_minor > 0),
  rate_basis_points integer not null check (rate_basis_points between 1000 and 10000),
  earning_minor bigint generated always as (
    (lesson_price_minor * rate_basis_points + 5000) / 10000
  ) stored,
  recorded_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);
create index individual_lesson_records_member_date_idx
  on public.individual_lesson_records(member_id, lesson_date desc);
create index individual_lesson_records_date_idx
  on public.individual_lesson_records(lesson_date desc);

alter table public.individual_lesson_records enable row level security;
revoke all on public.individual_lesson_records from anon, authenticated;
grant select on public.individual_lesson_records to authenticated;
create policy individual_lesson_records_admin_read
  on public.individual_lesson_records for select to authenticated
  using ((select private.is_admin()));

create function public.admin_record_individual_lesson(
  target_member_id uuid,
  target_lesson_date date,
  target_lesson_price_minor bigint,
  target_rate_basis_points integer
)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare new_id uuid;
begin
  if not (select private.is_admin()) then raise exception 'Admin access required'; end if;
  if target_lesson_date > (now() at time zone 'Europe/Istanbul')::date then
    raise exception 'Lesson date cannot be in the future';
  end if;
  if target_lesson_price_minor <= 0 then raise exception 'Lesson price must be positive'; end if;
  if target_rate_basis_points not between 1000 and 10000 then
    raise exception 'Rate must be between 10 and 100 percent';
  end if;
  if not exists (
    select 1 from public.profiles profile
    where profile.id = target_member_id and profile.is_active
  ) or exists (
    select 1 from public.user_roles role
    where role.user_id = target_member_id and role.role = 'admin'
  ) then
    raise exception 'Select an active member';
  end if;
  insert into public.individual_lesson_records(
    member_id, lesson_date, lesson_price_minor, rate_basis_points, recorded_by
  ) values (
    target_member_id, target_lesson_date, target_lesson_price_minor,
    target_rate_basis_points, (select auth.uid())
  ) returning id into new_id;
  return new_id;
end;
$$;
revoke all on function public.admin_record_individual_lesson(uuid, date, bigint, integer)
  from public, anon, authenticated;
grant execute on function public.admin_record_individual_lesson(uuid, date, bigint, integer)
  to authenticated;

commit;
