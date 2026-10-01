# Page 10: Post-class feedback

Status: awaiting user review.

Source: `lib/features/bookings/pages/class_feedback_page.dart`.

## What the screen contains

The feedback icon in the member dashboard opens a short post-class record.
For each attended class without feedback, the member selects:

1. **Ders nasıldı?** — Bana uygun değildi, İyiydi, Çok sevdim.
2. **Ne kadar zorlayıcıydı?** — Kolay, Tam kararında, Zorlayıcı.

Both selections are required, then one save action records the response. Past
responses remain visible in the same view as the member's history.

## Data and privacy

`20261002000100_post_class_feedback.sql` is prepared but not applied. It binds
one feedback row to one booking, accepts values from 1–3 only, and permits a
member to insert or update feedback only for their own `attended` booking.
Admins can read records for studio/instructor follow-up; other members cannot
read them. The migration must be applied after the fixed-series booking
migration because it references `bookings`.

## Behavior to review

- The record is intentionally limited to two quick choices; no free-text data
  is collected in this first version.
- Feedback is unavailable before a class has been marked attended.
- Saving again updates the member's own existing response rather than creating
  duplicates.
- The empty and load-error states are distinct and localized in English/Turkish.

## Review notes

User feedback: pending.
Approval: pending.
