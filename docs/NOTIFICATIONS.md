# Push notification plan

Status: local client, database migration and Edge Function implementation are
prepared. Apple/Firebase account configuration and production secret entry are
still required before deployment.

## Goal

1. Notify every administrator when a member creates a cash package request.
2. A notification tap opens the app directly at the cash-payment approval
   screen, with the relevant request selected when appropriate.
3. Notify the member after an administrator confirms their package.
4. Notify every active, non-admin member when an administrator publishes a new
   class series.
5. Notify every active administrator when an email-confirmed account enters the
   registration-approval queue.

## Proposed architecture

- Use Firebase Cloud Messaging (FCM) for iOS and future Android push delivery.
- Supabase Auth persists a signed-in session on the device. Separately, after a
  successful login, the app obtains the FCM registration token and stores it in
  a new RLS-protected `user_push_devices` table, tied to the authenticated
  `user_id`. Token refreshes update this row; sign-out removes the device link.
- Existing database RPCs remain the authority for purchase requests and
  approvals. They create a server-side notification event only after their
  database changes succeed.
- A Supabase Edge Function receives that event, selects the intended device
  tokens, and sends the FCM payload. Firebase service-account credentials live
  only in Supabase Edge Function secrets, never in Flutter or SQL migrations.
- Notification payloads contain only an opaque action and request ID, for
  example `action: cash_request` and `request_id: <uuid>`. New-class events
  use `action: class_created` and `class_series_id: <uuid>`. The app reloads
  RLS-protected data after it opens; names, prices, and other private details
  are not placed in the push payload.
- Registration-approval events use `action: registration_pending` and an
  opaque profile ID; a notification tap opens the administrator's user queue.
- Flutter handles foreground messages, background notification taps, and
  terminated-app launches using FCM's message-open APIs. The target screen
  still performs its normal admin/RLS checks.

## Required external setup

1. Finish the Apple Developer account.
2. Register the final iOS bundle identifier in Firebase. The current project
   identifier is `com.muticansel.backstreetpilates`.
3. Add Firebase's `GoogleService-Info.plist` to the iOS Runner target. It is
   intentionally ignored by Git.
4. In Xcode, enable Push Notifications plus Background Modes / Remote
   notifications.
5. Create an APNs `.p8` authentication key and upload it to Firebase with its
   Key ID and Apple Team ID.
6. Create Firebase service-account credentials and set them as a Supabase Edge
   Function secret. Do not commit them or paste them into Flutter.

## Implemented locally

1. `firebase_core` and `firebase_messaging` initialize on configured iOS/Android
   launches. Permission is requested only after an authenticated user reaches
   their home screen, not on login/signup.
2. `20261004000100_push_notification_foundation.sql` creates the RLS-protected
   device registry and an opaque notification outbox. The migration also
   records events after cash-request creation and confirmation succeeds.
3. `send-push-notification` is a Supabase Edge Function that accepts a database
   webhook, resolves only the intended user's active FCM tokens and sends an
   opaque action/request ID payload. Invalid device tokens are deleted.
4. A tap on an admin cash-request notification opens the existing approval
   queue only after the app resolves that user as an admin.
5. `20261006000100_class_created_notifications.sql` adds a trigger on
   `class_series`. Each newly created series creates one opaque outbox event
   for every profile whose `is_active` value is true and whose role is not
   `admin`. The Edge Function sends these events with the copy: “Yeni bir ders
   satışa açıldı.”
6. `20261008000200_admin_registration_notifications.sql` creates one opaque
   outbox event for every active administrator whenever a profile first enters
   `pending_admin_approval` after email confirmation. The trigger is attached
   to the profile status transition, so it also supports email providers that
   create a confirmed account directly. A tap opens the admin user queue.

## Remaining deployment steps

1. Apply `20261004000100_push_notification_foundation.sql`, then
   `20261006000100_class_created_notifications.sql`, then
   `20261008000200_admin_registration_notifications.sql`, in Supabase SQL
   Editor after the existing cash-purchase and registration-approval migrations.
2. In Supabase Edge Function secrets, add `FIREBASE_SERVICE_ACCOUNT_JSON` and
   a long random `NOTIFICATION_WEBHOOK_SECRET`. Neither value belongs in Git or
   Flutter.
3. Deploy `send-push-notification`, then create a Supabase Database Webhook for
   `public.notification_events` INSERT events. It must call the deployed
   function and send the `x-notification-secret` header.
4. Test on a physical iPhone. The iOS simulator is not sufficient for full APNs
   delivery testing.

## Notification outbox retention

`notification_events` is an outbox, not a permanent notification history. To
keep it small, delete only events that have a successful delivery timestamp.
Failed events are intentionally retained for investigation.

Enable the `pg_cron` extension first in **Database → Extensions**. If the Cron
screen reports `relation "cron.job" does not exist`, the extension is not
enabled yet.

Create this Supabase Cron job:

- Job name: `purge-delivered-notification-events`
- Schedule: `15 0 * * *` (03:15 Europe/Istanbul; Supabase Cron uses UTC)
- SQL:

```sql
delete from public.notification_events
where delivered_at is not null
  and delivered_at < now() - interval '30 days';
```

This runs daily so successfully delivered rows are retained for roughly 30
days, rather than potentially almost 60 days with a monthly task. Review the
job's run log after creation. A separate, longer retention rule for
`failed_at` rows may be added later if operational review needs it.

## Original implementation order

1. Add `firebase_core` and `firebase_messaging`; initialize them before the
   app starts and request notification permission after an authenticated user
   reaches their home screen.
2. Add the device-token and notification-event migration with RLS, indexes,
   retention, and token invalidation handling.
3. Add the secured Supabase Edge Function and deploy it with secrets.
4. Extend the cash-request and confirmation flow to create notification
   events, then connect notification taps to the admin queue.
5. Test on a physical iPhone. The iOS simulator is not sufficient for full APNs
   delivery testing.

## Deferred decision

Ask whether members should be able to switch package/payment notifications off
independently after the initial permission prompt.
