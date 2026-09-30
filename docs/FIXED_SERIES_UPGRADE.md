# Fixed-series booking upgrade

Your Supabase project has the earlier manual class-session draft. The current
`20261001000100_class_booking_foundation.sql` uses different tables and RPCs,
so do not run it over the old schema directly.

## Before you run anything

`20261001000200_remove_manual_booking_draft.sql` drops the old manual draft
and its data. Run it only after explicitly deciding those old records are
disposable. Use `20261001000300_archive_manual_booking_draft.sql` instead if
they must be retained.

## SQL Editor order

1. Run `20261001000200_remove_manual_booking_draft.sql` only when the old
   draft remains in the database and its data is explicitly disposable.
2. If old draft records must be kept, run
   `20261001000300_archive_manual_booking_draft.sql` instead. It renames the
   old tables to `legacy_manual_*`; it does not delete their rows.
3. Run the complete current contents of
   `20261001000100_class_booking_foundation.sql`.
4. Run `notify pgrst, 'reload schema';` once, then restart the Flutter app.

The resulting model removes manual member assignment and the earlier
offer-to-series setup step. An admin creates the sellable package, its fixed
weekly schedule and its dated sessions in one action. Pending cash requests
hold all future seats; payment approval creates all bookings automatically.
Oran is capped at 3 seats and İncek at 6 by the server RPC.
