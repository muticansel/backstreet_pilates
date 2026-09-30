-- Non-destructive upgrade path for a database that contains manual-draft data.
-- Run this file instead of 20261001000200 when the old tables have rows.
-- Then run the current 20261001000100_class_booking_foundation.sql manually.
begin;

drop function if exists public.admin_create_booking(uuid, uuid);
drop function if exists public.admin_create_class_session(uuid, text, timestamptz, timestamptz, integer);
drop function if exists public.admin_create_class_session(uuid, timestamptz, timestamptz);
drop function if exists public.admin_create_class_series(uuid, text, integer);

-- These indexes have names reused by the new schema. Removing indexes does
-- not remove their underlying archived records.
drop index if exists public.one_active_booking_per_member_session_idx;
drop index if exists public.bookings_member_upcoming_idx;
drop index if exists public.class_sessions_upcoming_idx;
drop index if exists public.class_sessions_series_upcoming_idx;

alter table if exists public.bookings rename to legacy_manual_bookings;
alter table if exists public.class_sessions rename to legacy_manual_class_sessions;
alter table if exists public.purchase_request_session_holds rename to legacy_manual_session_holds;
alter table if exists public.branch_offer_class_series rename to legacy_manual_offer_class_series;
alter table if exists public.class_series rename to legacy_manual_class_series;

commit;
