-- Member-editable profile fields. Email remains in Supabase Auth.
begin;

alter table public.profiles
  add column if not exists birth_date date,
  add column if not exists gender text check (
    gender is null or gender in ('female', 'male', 'non_binary', 'prefer_not_to_say')
  );

grant update (display_name, phone, birth_date, gender) on public.profiles to authenticated;

commit;
