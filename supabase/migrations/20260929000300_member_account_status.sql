begin;

alter table public.profiles
  add column if not exists is_active boolean not null default true,
  add column if not exists deactivated_at timestamptz,
  add column if not exists deactivated_by uuid references auth.users(id);

create index if not exists profiles_active_idx on public.profiles(is_active, display_name);

commit;
