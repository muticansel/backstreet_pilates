-- Summarise operational history after 30 days, then remove only data that is
-- no longer needed for member-facing schedules. Financial, membership, audit,
-- profile and failed-notification records are intentionally out of scope.
begin;

create table public.member_activity_monthly_summaries (
  user_id uuid not null references auth.users(id) on delete restrict,
  activity_month date not null,
  group_class_count integer not null default 0 check (group_class_count >= 0),
  private_lesson_count integer not null default 0 check (private_lesson_count >= 0),
  no_show_count integer not null default 0 check (no_show_count >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, activity_month),
  check (activity_month = date_trunc('month', activity_month)::date)
);

create table private.operational_retention_runs (
  id bigint generated always as identity primary key,
  ran_at timestamptz not null default now(),
  cutoff_at timestamptz not null,
  delivered_notifications_deleted integer not null default 0,
  bookings_deleted integer not null default 0,
  sessions_deleted integer not null default 0,
  private_requests_deleted integer not null default 0
);

alter table public.member_activity_monthly_summaries enable row level security;
revoke all on public.member_activity_monthly_summaries from anon, authenticated;
grant select on public.member_activity_monthly_summaries to authenticated;
create policy activity_summaries_read_own_or_admin
  on public.member_activity_monthly_summaries for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));

create function public.run_operational_retention()
returns void language plpgsql security definer set search_path = ''
as $$
declare
  cutoff_at timestamptz := now() - interval '30 days';
  deleted_notifications integer := 0;
  deleted_bookings integer := 0;
  deleted_sessions integer := 0;
  deleted_private_requests integer := 0;
begin
  -- Group-class summaries are calculated before deleting attended/no-show
  -- bookings. The delete in this transaction makes a retry idempotent.
  insert into public.member_activity_monthly_summaries (
    user_id, activity_month, group_class_count, no_show_count, updated_at
  )
  select
    booking.user_id,
    date_trunc('month', session.starts_at at time zone 'Europe/Istanbul')::date,
    count(*)::integer,
    count(*) filter (where booking.status = 'no_show')::integer,
    now()
  from public.bookings booking
  join public.class_sessions session on session.id = booking.class_session_id
  where session.ends_at < cutoff_at
    and booking.status in ('attended', 'no_show')
  group by booking.user_id,
    date_trunc('month', session.starts_at at time zone 'Europe/Istanbul')::date
  on conflict (user_id, activity_month) do update set
    group_class_count = public.member_activity_monthly_summaries.group_class_count
      + excluded.group_class_count,
    no_show_count = public.member_activity_monthly_summaries.no_show_count
      + excluded.no_show_count,
    updated_at = excluded.updated_at;

  -- Only approved, completed private lessons count as completed activity.
  insert into public.member_activity_monthly_summaries (
    user_id, activity_month, private_lesson_count, updated_at
  )
  select
    request.member_user_id,
    date_trunc('month', request.starts_at at time zone 'Europe/Istanbul')::date,
    count(*)::integer,
    now()
  from public.private_lesson_requests request
  where request.ends_at < cutoff_at and request.status = 'approved'
  group by request.member_user_id,
    date_trunc('month', request.starts_at at time zone 'Europe/Istanbul')::date
  on conflict (user_id, activity_month) do update set
    private_lesson_count = public.member_activity_monthly_summaries.private_lesson_count
      + excluded.private_lesson_count,
    updated_at = excluded.updated_at;

  -- A delivered outbox event has no operational value after 30 days. Failed
  -- and undelivered events remain available for investigation.
  delete from public.notification_events
  where delivered_at is not null and delivered_at < cutoff_at;
  get diagnostics deleted_notifications = row_count;

  -- Feedback cascades from bookings, which deliberately removes only the
  -- associated raw feedback record and never a membership or payment record.
  delete from public.bookings booking
  using public.class_sessions session
  where session.id = booking.class_session_id
    and session.ends_at < cutoff_at
    and booking.status in ('attended', 'no_show', 'cancelled');
  get diagnostics deleted_bookings = row_count;

  delete from public.class_sessions session
  where session.ends_at < cutoff_at
    and session.status in ('completed', 'cancelled')
    and not exists (
      select 1 from public.bookings booking
      where booking.class_session_id = session.id
    )
    and not exists (
      select 1 from public.purchase_request_session_holds hold
      where hold.class_session_id = session.id
    );
  get diagnostics deleted_sessions = row_count;

  -- Do not cascade away a failed or undelivered notification investigation.
  delete from public.private_lesson_requests request
  where request.ends_at < cutoff_at
    and request.status in ('approved', 'rejected', 'cancelled')
    and not exists (
      select 1 from public.notification_events event
      where event.private_lesson_request_id = request.id
        and (event.failed_at is not null or event.delivered_at is null)
    );
  get diagnostics deleted_private_requests = row_count;

  insert into private.operational_retention_runs (
    cutoff_at,
    delivered_notifications_deleted,
    bookings_deleted,
    sessions_deleted,
    private_requests_deleted
  ) values (
    cutoff_at,
    deleted_notifications,
    deleted_bookings,
    deleted_sessions,
    deleted_private_requests
  );
end;
$$;

revoke all on function public.run_operational_retention() from public, anon, authenticated;

comment on table public.member_activity_monthly_summaries is
  'Non-identifying monthly counts retained after 30-day operational history cleanup.';
comment on table private.operational_retention_runs is
  'Server-only evidence of successful operational retention executions.';
comment on function public.run_operational_retention() is
  'Server-only, transactional 30-day retention job. Schedule with pg_cron after review.';

commit;
