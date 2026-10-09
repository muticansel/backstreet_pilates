-- Guarantees a member receives a notification event when an administrator
-- approves a private lesson request. Safe to apply after the original private
-- lesson migration if the feature was installed incrementally.
begin;

alter table public.notification_events
  add column if not exists private_lesson_request_id uuid
    references public.private_lesson_requests(id) on delete cascade;

alter table public.notification_events
  drop constraint if exists notification_events_check,
  drop constraint if exists notification_events_event_type_check,
  drop constraint if exists notification_events_payload_check;

alter table public.notification_events
  add constraint notification_events_event_type_check
  check (event_type in (
    'cash_request_created',
    'cash_request_confirmed',
    'class_created',
    'registration_approval_requested',
    'private_lesson_request_approved'
  ));

alter table public.notification_events
  add constraint notification_events_payload_check check (
    (event_type = 'cash_request_created' and request_id is not null and class_series_id is null and registration_profile_id is null and private_lesson_request_id is null and payload = jsonb_build_object('action', 'cash_request', 'request_id', request_id))
    or (event_type = 'cash_request_confirmed' and request_id is not null and class_series_id is null and registration_profile_id is null and private_lesson_request_id is null and payload = jsonb_build_object('action', 'package_confirmed', 'request_id', request_id))
    or (event_type = 'class_created' and request_id is null and class_series_id is not null and registration_profile_id is null and private_lesson_request_id is null and payload = jsonb_build_object('action', 'class_created', 'class_series_id', class_series_id))
    or (event_type = 'registration_approval_requested' and request_id is null and class_series_id is null and registration_profile_id is not null and private_lesson_request_id is null and payload = jsonb_build_object('action', 'registration_pending', 'registration_profile_id', registration_profile_id))
    or (event_type = 'private_lesson_request_approved' and request_id is null and class_series_id is null and registration_profile_id is null and private_lesson_request_id is not null and payload = jsonb_build_object('action', 'private_lesson_approved', 'private_lesson_request_id', private_lesson_request_id))
  );

create or replace function private.enqueue_private_lesson_approval_notification()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if old.status = 'pending' and new.status = 'approved' then
    insert into public.notification_events(
      event_type,
      recipient_user_id,
      private_lesson_request_id,
      payload
    ) values (
      'private_lesson_request_approved',
      new.member_user_id,
      new.id,
      jsonb_build_object(
        'action', 'private_lesson_approved',
        'private_lesson_request_id', new.id
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists private_lesson_approval_notification
  on public.private_lesson_requests;
create trigger private_lesson_approval_notification
  after update of status on public.private_lesson_requests
  for each row execute function private.enqueue_private_lesson_approval_notification();

commit;
