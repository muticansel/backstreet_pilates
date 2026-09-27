-- Run ONLY on the development project after the initial catalog migration and
-- 20260927000200_video_library.sql. Everything is rolled back at the end.
begin;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-4000-8000-000000000011',
    'authenticated', 'authenticated', 'video-member@example.invalid', '', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '00000000-0000-4000-8000-000000000012',
    'authenticated', 'authenticated', 'no-video-access@example.invalid', '', now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now()
  );

insert into public.video_series (id, slug, title, access_duration_days, is_published)
values
  ('00000000-0000-4000-8000-000000000101', 'test-series', 'Test series', 365, true),
  ('00000000-0000-4000-8000-000000000102', 'draft-series', 'Draft series', 365, false);
insert into public.series_videos (id, series_id, title, sort_order, is_published)
values
  ('00000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000101', 'Published video', 0, true),
  ('00000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-000000000102', 'Draft video', 0, false);
insert into private.video_playback_assets (video_id, provider, asset_id)
values ('00000000-0000-4000-8000-000000000201', 'mux', 'test-private-asset');
insert into public.video_series_access (user_id, series_id, starts_at, expires_at, grant_source)
values (
  '00000000-0000-4000-8000-000000000011',
  '00000000-0000-4000-8000-000000000101',
  now() - interval '1 minute', now() + interval '365 days', 'admin'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000011', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000011","role":"authenticated"}', true);
do $$ begin
  if (select count(*) from public.video_series) <> 1 then
    raise exception 'Member can read draft series';
  end if;
  if (select count(*) from public.series_videos) <> 1 then
    raise exception 'Member can read draft videos';
  end if;
  if (select count(*) from public.video_series_access) <> 1 then
    raise exception 'Member cannot read own access';
  end if;
  insert into public.video_progress(user_id, video_id, watched_seconds)
  values (auth.uid(), '00000000-0000-4000-8000-000000000201', 42);
  if (select watched_seconds from public.video_progress) <> 42 then
    raise exception 'Member progress was not saved';
  end if;
  begin
    insert into public.video_series_access(user_id, series_id, starts_at, expires_at, grant_source)
    values (auth.uid(), '00000000-0000-4000-8000-000000000101', now(), now() + interval '1 day', 'admin');
    raise exception 'Member was allowed to grant video access';
  exception when insufficient_privilege then null;
  end;
  begin
    perform 1 from private.video_playback_assets;
    raise exception 'Member was allowed to read playback assets';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000012', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-4000-8000-000000000012","role":"authenticated"}', true);
do $$ begin
  if exists (select 1 from public.video_series_access) then
    raise exception 'Member can read another member access';
  end if;
  begin
    insert into public.video_progress(user_id, video_id, watched_seconds)
    values (auth.uid(), '00000000-0000-4000-8000-000000000201', 1);
    raise exception 'Member without access saved progress';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;
set local role anon;
do $$ begin
  begin
    perform 1 from public.video_series;
    raise exception 'Anonymous access to video catalogue was allowed';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
rollback;
