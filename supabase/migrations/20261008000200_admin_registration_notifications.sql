-- Notify active administrators after a new account reaches the approval queue.
-- The profile approval-status transition is used instead of an auth trigger so
-- it also covers providers that create an already email-confirmed account.
begin;

alter table public.notification_events
  add column if not exists registration_profile_id uuid
    references public.profiles(id) on delete cascade;

alter table public.notification_events
  drop constraint if exists notification_events_event_type_check,
  drop constraint if exists notification_events_payload_check;

alter table public.notification_events
  add constraint notification_events_event_type_check
    check (event_type in (
      'cash_request_created',
      'cash_request_confirmed',
      'class_created',
      'registration_approval_requested'
    )),
  add constraint notification_events_payload_check check (
    (
      event_type = 'cash_request_created'
      and request_id is not null
      and class_series_id is null
      and registration_profile_id is null
      and payload = jsonb_build_object('action', 'cash_request', 'request_id', request_id)
    ) or (
      event_type = 'cash_request_confirmed'
      and request_id is not null
      and class_series_id is null
      and registration_profile_id is null
      and payload = jsonb_build_object('action', 'package_confirmed', 'request_id', request_id)
    ) or (
      event_type = 'class_created'
      and request_id is null
      and class_series_id is not null
      and registration_profile_id is null
      and payload = jsonb_build_object(
        'action', 'class_created',
        'class_series_id', class_series_id
      )
    ) or (
      event_type = 'registration_approval_requested'
      and request_id is null
      and class_series_id is null
      and registration_profile_id is not null
      and payload = jsonb_build_object(
        'action', 'registration_pending',
        'registration_profile_id', registration_profile_id
      )
    )
  );

create index if not exists notification_events_registration_profile_idx
  on public.notification_events(registration_profile_id)
  where registration_profile_id is not null;

create function private.enqueue_registration_approval_notification()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if new.approval_status = 'pending_admin_approval'
    and (tg_op = 'INSERT' or old.approval_status is distinct from new.approval_status) then
    insert into public.notification_events (
      event_type,
      recipient_user_id,
      registration_profile_id,
      payload
    )
    select
      'registration_approval_requested',
      role.user_id,
      new.id,
      jsonb_build_object(
        'action', 'registration_pending',
        'registration_profile_id', new.id
      )
    from public.user_roles role
    join public.profiles administrator on administrator.id = role.user_id
    where role.role = 'admin'
      and administrator.is_active;
  end if;
  return new;
end;
$$;
revoke all on function private.enqueue_registration_approval_notification()
  from public, anon, authenticated;

drop trigger if exists profile_registration_approval_notification on public.profiles;
create trigger profile_registration_approval_notification
  after insert or update of approval_status on public.profiles
  for each row execute function private.enqueue_registration_approval_notification();

comment on function private.enqueue_registration_approval_notification() is
  'Creates one opaque push outbox event per active administrator when an email-confirmed account enters the approval queue.';

commit;
