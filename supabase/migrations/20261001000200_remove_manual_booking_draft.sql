-- Upgrade prerequisite for databases that already applied the old manual
-- class-session draft. Run this file first, then run the current contents of
-- 20261001000100_class_booking_foundation.sql in Supabase SQL Editor.
--
-- The user approved removal of the old manual draft and its test data.
begin;

drop function if exists public.admin_create_booking(uuid, uuid);
drop function if exists public.admin_create_class_session(uuid, text, timestamptz, timestamptz, integer);
drop function if exists public.admin_create_class_session(uuid, timestamptz, timestamptz);
drop function if exists public.admin_create_class_series(uuid, text, integer);

drop table if exists public.purchase_request_session_holds;
drop table if exists public.bookings;
drop table if exists public.class_sessions;
drop table if exists public.branch_offer_class_series;
drop table if exists public.class_series;

commit;
