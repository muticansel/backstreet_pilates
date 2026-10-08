# Registration approval notification

## Scope

After an account completes email confirmation and reaches
`pending_admin_approval`, every active administrator receives a push event.
The payload contains only an action and opaque profile ID. It contains no name,
email address, or other registration data.

## Delivery and navigation

- `20261008000200_admin_registration_notifications.sql` appends one outbox row
  per active admin from a `profiles` status-transition trigger.
- The existing `send-push-notification` Edge Function validates and delivers
  the new event type.
- The app checks the recipient's current role before opening `AdminUsersPage`.

## Deployment and checks

Apply the migration only after the push-notification and registration-approval
migrations, redeploy the Edge Function, and ensure the existing database
webhook watches `public.notification_events` INSERT events. Confirm the flow on
a physical device: sign up, confirm email, receive the admin push, tap it, and
approve the account from the user queue.
