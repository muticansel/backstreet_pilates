# Member classes and reservations

Status: ready for review. The SQL migration has not been applied to Supabase.

## What is included

- A **My classes / Derslerim** member-navigation tab.
- The signed-in member can see only their future `booked` or `attended`
  reservations, ordered by date and rendered in the device's local time.
- Pull-to-refresh reloads the schedule. Empty and error states are explicit.
- `class_sessions`, `bookings`, recurring weekly slots and purchase-seat holds
  are prepared in `20261001000100_class_booking_foundation.sql` with RLS and
  server-side RPCs.
- **Class schedule / Ders takvimi** creates a complete sellable package in one
  form: package name, branch, TRY price, capacity, total classes, weekly class
  count, first class date, and each weekly day/time. The server creates the
  package, offer, fixed series and every dated class in one transaction.
- An active package appears automatically in the member **Packages** tab.
  Removing it hides it from new sales while preserving past sales and class
  records.
- Members are never manually assigned. A cash request reserves all required
  seats. Admin confirmation automatically turns those holds into the member's
  bookings, which appear in **My classes / Derslerim** only while future-dated.

## Deliberately not included yet

The initial product uses fixed recurring package slots. There is no member-side
create, reschedule or cancel operation. The migration grants the Flutter client
no direct table write permission.

The fixed-series package creation, purchase operation and confirmation RPCs
verify, in transactions:

1. a package's total classes divide evenly by its weekly class count;
2. its first class date is one of its selected weekly days;
3. Oran capacity is at most 3 and İncek capacity is at most 6;
4. every required future session exists and still has capacity, counting pending
   cash holds; and
5. the complete schedule is turned into bookings only after payment
   confirmation.

All package credits are allocated to its fixed future bookings at confirmation,
so `remaining_credits` becomes zero. A later cancellation policy must use a
separate audited adjustment; it must not be a client-side update.

## Required review decision

Before enabling member-initiated cancellation or class changes, confirm the
late-cancellation cutoff, whether a credit is returned, and whether the first
release allows changes at all for fixed packages.
