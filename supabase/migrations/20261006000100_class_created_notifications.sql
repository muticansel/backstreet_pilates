-- Notify active members when an admin publishes a new class series.
-- Delivery is still handled by the existing send-push-notification Edge Function.
begin;

alter table public.notification_events
  add column if not exists class_series_id uuid
    references public.class_series(id) on delete cascade;

alter table public.notification_events
  alter column request_id drop not null;

alter table public.notification_events
  drop constraint if exists notification_events_event_type_check,
  drop constraint if exists notification_events_payload_check;

alter table public.notification_events
  add constraint notification_events_event_type_check
    check (event_type in (
      'cash_request_created',
      'cash_request_confirmed',
      'class_created'
    )),
  add constraint notification_events_payload_check check (
    (
      event_type = 'cash_request_created'
      and request_id is not null
      and class_series_id is null
      and payload = jsonb_build_object('action', 'cash_request', 'request_id', request_id)
    ) or (
      event_type = 'cash_request_confirmed'
      and request_id is not null
      and class_series_id is null
      and payload = jsonb_build_object('action', 'package_confirmed', 'request_id', request_id)
    ) or (
      event_type = 'class_created'
      and request_id is null
      and class_series_id is not null
      and payload = jsonb_build_object(
        'action', 'class_created',
        'class_series_id', class_series_id
      )
    )
  );

create index if not exists notification_events_class_series_idx
  on public.notification_events(class_series_id)
  where class_series_id is not null;

create function private.enqueue_class_created_notification()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  -- The series is created only by the admin-only creation RPC. A profile must
  -- be active to receive push, and no admin account is included as a recipient.
  insert into public.notification_events (
    event_type,
    recipient_user_id,
    class_series_id,
    payload
  )
  select
    'class_created',
    profile.id,
    new.id,
    jsonb_build_object('action', 'class_created', 'class_series_id', new.id)
  from public.profiles profile
  where profile.is_active
    and not exists (
      select 1
      from public.user_roles role
      where role.user_id = profile.id
        and role.role = 'admin'
    );
  return new;
end;
$$;
revoke all on function private.enqueue_class_created_notification()
  from public, anon, authenticated;

drop trigger if exists class_series_created_notification on public.class_series;
create trigger class_series_created_notification
  after insert on public.class_series
  for each row execute function private.enqueue_class_created_notification();

comment on function private.enqueue_class_created_notification() is
  'Creates one opaque push outbox event per active non-admin user for each newly published class series.';

commit;
