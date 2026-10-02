-- Split the legacy display name into required profile fields.
begin;

alter table public.profiles
  add column if not exists first_name text,
  add column if not exists last_name text;

-- Existing profiles only have display_name. Keep them editable and non-empty
-- until each member replaces these temporary values with their real name.
update public.profiles
set
  first_name = coalesce(nullif(trim(first_name), ''), nullif(trim(display_name), ''), 'Member'),
  last_name = coalesce(nullif(trim(last_name), ''), nullif(trim(display_name), ''), 'Member');

alter table public.profiles
  alter column first_name set not null,
  alter column last_name set not null,
  add constraint profiles_first_name_not_blank check (length(trim(first_name)) > 0),
  add constraint profiles_last_name_not_blank check (length(trim(last_name)) > 0);

create or replace function private.create_user_profile()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  profile_first_name text := trim(coalesce(new.raw_user_meta_data ->> 'first_name', ''));
  profile_last_name text := trim(coalesce(new.raw_user_meta_data ->> 'last_name', ''));
begin
  if profile_first_name = '' or profile_last_name = '' then
    raise exception 'First name and last name are required';
  end if;
  insert into public.profiles(id, first_name, last_name, display_name)
  values (
    new.id,
    profile_first_name,
    profile_last_name,
    profile_first_name || ' ' || profile_last_name
  );
  insert into public.user_roles(user_id, role) values (new.id, 'member');
  return new;
end;
$$;

grant update (display_name, first_name, last_name, phone, birth_date, gender)
  on public.profiles to authenticated;

commit;
