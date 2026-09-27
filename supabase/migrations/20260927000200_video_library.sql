-- Paid video-library foundation. Streaming URLs remain server-only and are
-- intentionally absent from the public schema.
begin;

create table public.video_series (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  title text not null check (length(trim(title)) > 0),
  description text not null default '',
  cover_image_url text,
  access_duration_days integer not null default 365
    check (access_duration_days between 1 and 3650),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.series_videos (
  id uuid primary key default gen_random_uuid(),
  series_id uuid not null references public.video_series(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  description text not null default '',
  sort_order integer not null check (sort_order >= 0),
  duration_seconds integer check (duration_seconds is null or duration_seconds > 0),
  thumbnail_url text,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (series_id, sort_order)
);
create index series_videos_series_id_idx on public.series_videos(series_id);

-- Provider asset identifiers stay private. The future Edge Function reads this
-- table after checking the caller's access and returns a short-lived playback URL.
create table private.video_playback_assets (
  video_id uuid primary key references public.series_videos(id) on delete cascade,
  provider text not null check (provider in ('mux', 'cloudflare_stream')),
  asset_id text not null unique check (length(trim(asset_id)) > 0),
  created_at timestamptz not null default now()
);

create table public.video_series_access (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  series_id uuid not null references public.video_series(id) on delete restrict,
  starts_at timestamptz not null,
  expires_at timestamptz not null,
  grant_source text not null check (grant_source in (
    'app_store', 'play_store', 'admin', 'complimentary', 'migration'
  )),
  purchase_reference text unique,
  revoked_at timestamptz,
  revoke_reason text,
  created_at timestamptz not null default now(),
  check (expires_at > starts_at),
  check ((revoked_at is null) = (revoke_reason is null))
);
create index video_series_access_active_lookup_idx
  on public.video_series_access(user_id, series_id, expires_at)
  where revoked_at is null;

create table public.video_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  video_id uuid not null references public.series_videos(id) on delete cascade,
  watched_seconds integer not null default 0 check (watched_seconds >= 0),
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, video_id)
);

create function private.can_watch_video(target_video_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.series_videos video
    join public.video_series series on series.id = video.series_id
    join public.video_series_access access on access.series_id = series.id
    where video.id = target_video_id
      and video.is_published
      and series.is_published
      and access.user_id = (select auth.uid())
      and access.starts_at <= now()
      and access.expires_at > now()
      and access.revoked_at is null
  );
$$;
revoke all on function private.can_watch_video(uuid) from public, anon, authenticated;
grant execute on function private.can_watch_video(uuid) to authenticated;

alter table public.video_series enable row level security;
alter table public.series_videos enable row level security;
alter table public.video_series_access enable row level security;
alter table public.video_progress enable row level security;

revoke all on public.video_series, public.series_videos, public.video_series_access,
  public.video_progress from anon, authenticated;
grant select on public.video_series, public.series_videos, public.video_series_access,
  public.video_progress to authenticated;
grant insert, update, delete on public.video_series, public.series_videos to authenticated;
grant insert, update, delete on public.video_progress to authenticated;

create policy video_series_read on public.video_series for select to authenticated
using (is_published or (select private.is_admin()));
create policy video_series_admin on public.video_series for all to authenticated
using ((select private.is_admin())) with check ((select private.is_admin()));

create policy series_videos_read on public.series_videos for select to authenticated
using (
  (is_published and exists (
    select 1 from public.video_series series
    where series.id = series_id and series.is_published
  )) or (select private.is_admin())
);
create policy series_videos_admin on public.series_videos for all to authenticated
using ((select private.is_admin())) with check ((select private.is_admin()));

create policy video_series_access_read on public.video_series_access
for select to authenticated
using (user_id = (select auth.uid()) or (select private.is_admin()));
-- Access grants are only written by a verified payment webhook or an admin-only
-- server operation; the Flutter client has no write privilege.

create policy video_progress_read on public.video_progress for select to authenticated
using (user_id = (select auth.uid()));
create policy video_progress_insert on public.video_progress for insert to authenticated
with check (
  user_id = (select auth.uid())
  and (select private.can_watch_video(video_id))
);
create policy video_progress_update on public.video_progress for update to authenticated
using (user_id = (select auth.uid()) and (select private.can_watch_video(video_id)))
with check (
  user_id = (select auth.uid())
  and (select private.can_watch_video(video_id))
);
create policy video_progress_delete on public.video_progress for delete to authenticated
using (user_id = (select auth.uid()));

comment on table public.video_series_access is
  'A purchased or manually granted period of access. Payment verification is server-only.';
comment on table private.video_playback_assets is
  'Never expose provider asset IDs or playback URLs directly to Flutter clients.';
commit;
