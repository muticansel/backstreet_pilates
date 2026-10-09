# Private lesson calendar review

## Member flow

- **Classes** now includes **Book a private lesson**.
- **My private lessons** lets a member review only their own requests and
  confirmed lessons. Each record shows its local date, time and current status
  (awaiting approval, approved, declined or cancelled). The existing RLS
  policy remains the access boundary; the client does not receive another
  member's lesson details.
- A member picks a date within the next 60 days and sees one-hour slots from
  07:00 to 22:00 Istanbul time. Green slots are requestable; unavailable slots
  remain visible without exposing another member's identity or booking detail.
- A request holds the slot while it is pending, so two members cannot request
  the same instructor time. The request is not a paid booking and does not use
  a package credit.

## Admin flow

- **Private lesson requests** on the admin dashboard presents the selected
  week's pending requests, confirmed private lessons and blocked time.
- A pending request can be approved or declined. Approval makes it a confirmed
  calendar event and creates an opaque push-outbox event for that member.
- **Block time** accepts a whole-hour start and end over one or more dates. It
  rejects a range that overlaps an already approved private lesson.
- Every blocked-time card has a delete action with confirmation. Removing a
  block reopens that time; it never deletes a pending or approved lesson.

## Server rules

`20261009000100_private_lesson_calendar.sql` sets up the calendar feature. It
uses the active admin as the first instructor and serializes bookings per
instructor in the database, so client refresh timing cannot cause a double
reservation. It also extends `notification_events` and removes the legacy
`notification_events_check` constraint that previously interrupted new event
types.

`20261009000400_private_lesson_approval_notification.sql` is an idempotent
follow-up for installations where the calendar was applied incrementally. It
ensures every `pending → approved` transition inserts a
`private_lesson_request_approved` outbox event for the requesting member.

`20261010000100_member_private_lesson_request_read.sql` restores the member
read policy for `private_lesson_requests`. The member page also explicitly
filters by the current authenticated user's ID, while RLS remains the
authoritative access control.

After applying the notification migration, deploy the matching local
`send-push-notification` Edge Function and keep the existing database webhook
on `notification_events` INSERT. No secret or client service key is added.

## Review questions

1. Is 07:00–22:00 the intended standard private-lesson window?
2. Should a pending request temporarily hide the slot from other members, as it
does now, or should only approved lessons reserve it?
3. Should requesting/approving a private lesson create payment or package-credit
records in a later iteration?
