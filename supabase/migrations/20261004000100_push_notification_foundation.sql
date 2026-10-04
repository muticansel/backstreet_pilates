-- Device registration and notification outbox. Apply after the cash-purchase
-- migration. Delivery is performed by the send-push-notification Edge Function.
begin;

create table public.user_push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique check (length(token) > 20),
  platform text not null check (platform in ('ios', 'android')),
  push_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique (user_id, token)
);

create index user_push_devices_user_id_idx
  on public.user_push_devices(user_id) where push_enabled;

create table public.notification_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null check (event_type in (
    'cash_request_created', 'cash_request_confirmed'
  )),
  recipient_user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null references public.membership_purchase_requests(id)
    on delete cascade,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  delivered_at timestamptz,
  failed_at timestamptz,
  check (payload = jsonb_build_object(
    'action', case when event_type = 'cash_request_created' then 'cash_request' else 'package_confirmed' end,
    'request_id', request_id
  ))
);

create index notification_events_pending_idx
  on public.notification_events(created_at) where delivered_at is null and failed_at is null;

alter table public.user_push_devices enable row level security;
alter table public.notification_events enable row level security;
revoke all on public.user_push_devices, public.notification_events from anon, authenticated;
grant select, insert, update, delete on public.user_push_devices to authenticated;

create policy push_devices_read_own on public.user_push_devices for select to authenticated
  using (user_id = (select auth.uid()));
create policy push_devices_insert_own on public.user_push_devices for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy push_devices_update_own on public.user_push_devices for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy push_devices_delete_own on public.user_push_devices for delete to authenticated
  using (user_id = (select auth.uid()));

create function private.enqueue_purchase_notification()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' and new.status = 'cash_payment_pending' then
    insert into public.notification_events (event_type, recipient_user_id, request_id, payload)
    select
      'cash_request_created',
      role.user_id,
      new.id,
      jsonb_build_object('action', 'cash_request', 'request_id', new.id)
    from public.user_roles role
    where role.role = 'admin';
  elsif tg_op = 'UPDATE'
    and old.status = 'cash_payment_pending'
    and new.status = 'cash_payment_confirmed' then
    insert into public.notification_events (event_type, recipient_user_id, request_id, payload)
    values (
      'cash_request_confirmed',
      new.user_id,
      new.id,
      jsonb_build_object('action', 'package_confirmed', 'request_id', new.id)
    );
  end if;
  return new;
end;
$$;
revoke all on function private.enqueue_purchase_notification() from public, anon, authenticated;

create trigger membership_purchase_request_notification
  after insert or update of status on public.membership_purchase_requests
  for each row execute function private.enqueue_purchase_notification();

comment on table public.user_push_devices is
  'FCM registration tokens registered by the signed-in user. Tokens are not shared across users.';
comment on table public.notification_events is
  'Opaque notification outbox. Payloads deliberately contain no member, payment, or package data.';
commit;
