# Private lesson calendar review

## Member flow

- **Classes** now includes **Book a private lesson**.
- A member picks a date within the next 60 days and sees one-hour slots from
  07:00 to 22:00 Istanbul time. Green slots are requestable; unavailable slots
  remain visible without exposing another member's identity or booking detail.
- A request holds the slot while it is pending, so two members cannot request
  the same instructor time. The request is not a paid booking and does not use
  a package credit.

## Admin flow

- **Private lesson calendar** on the admin dashboard presents the selected
  week's pending requests, confirmed private lessons and blocked time.
- A pending request can be approved or declined. Approval makes it a confirmed
  calendar event and creates an opaque push-outbox event for that member.
- **Block time** accepts a whole-hour start and end over one or more dates. It
  rejects a range that overlaps an already approved private lesson.
- Every blocked-time card has a delete action with confirmation. Removing a
  block reopens that time; it never deletes a pending or approved lesson.

## Server rules

`20261009000100_private_lesson_calendar.sql` is prepared only; it has not been
applied to Supabase. It uses the active admin as the first instructor and
serializes bookings per instructor in the database, so client refresh timing
cannot cause a double reservation. It also extends `notification_events` and
removes the legacy `notification_events_check` constraint that previously
interrupted new event types.

After applying the migration, deploy the matching local
`send-push-notification` Edge Function and keep the existing database webhook
on `notification_events` INSERT. No secret or client service key is added.

## Review questions

1. Is 07:00–22:00 the intended standard private-lesson window?
2. Should a pending request temporarily hide the slot from other members, as it
does now, or should only approved lessons reserve it?
3. Should requesting/approving a private lesson create payment or package-credit
records in a later iteration?
