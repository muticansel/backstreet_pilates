# Page 12: Admin Today operations

Status: awaiting user review.

## What the page contains

The **Today / Bugün** page is an operational snapshot for admins:

1. Today's scheduled group sessions with each session's occupied seats and capacity.
2. The total occupancy percentage across today's sessions.
3. Members recorded as no-show for sessions occurring today.
4. Active packages whose final valid day falls in the next seven calendar days.
5. All pending cash payments, with a direct path to the approval queue.

The no-show section opens Attendance; the payment section opens Cash payment
requests. Both actions retain their existing server-side authorization.

## Data and access control

`admin_today_operations()` is a security-definer, read-only RPC. It validates
`private.is_admin()` before returning data and calculates today using
`Europe/Istanbul`, rather than the device clock. Flutter receives one snapshot,
which prevents the sections from drifting around midnight.

Apply `20261002000300_admin_today_operations.sql` after the existing booking
and purchase migrations. Until then, the page shows an empty state when the
unconfigured development gateway is used; a configured Supabase gateway will
report a load error until the migration is applied.

## Behavior to review

- Is a seven-day package-ending window the right lead time for staff follow-up?
- Should no-shows mean only the current day, or include a recent historical
  follow-up list as well?
- Are the two drill-down links sufficient for actioning no-shows and payments?
