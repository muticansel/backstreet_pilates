# Page 03: Supabase authentication

Status: awaiting user review.

This page review changes the behavior of the existing login and signup pages.
It does not add the member dashboard, admin panel, reservations, or payments.

## Code map

1. `lib/config/supabase_config.dart`: reads the URL and publishable key passed at launch.
2. `lib/main.dart`: initializes Supabase only when both values are present.
3. `lib/features/auth/data/auth_gateway.dart`: a small contract used by screens and tests.
4. `lib/features/auth/data/supabase_auth_gateway.dart`: performs password login and signup.
5. `login_page.dart`: validates, prevents repeat taps while waiting, and displays a safe failure message.
6. `signup_page.dart`: sends the display name as user metadata and directs users to confirm email when required.
7. `app.dart`: checks for a prior Supabase session at launch and opens the
   account home when one exists.

## Behavior to verify

- Login submits email and password to Supabase and retains no password outside the active form.
- Signup creates a standard member account only; signup data cannot assign the admin role.
- With Confirm email on, signup states that the user must confirm their email before logging in.
- Backend failure stays on the form and gives a non-sensitive message.
- Buttons prevent repeat submission while a request is running.
- Closing and reopening the app retains a valid Supabase session and opens the
  appropriate member or admin home without asking for credentials again.
- Signing out clears the Supabase session, so the next launch opens Login.
- Before account pages are built, a non-null session is verified through
  Supabase Auth. This avoids issuing first-login RLS reads while an anonymous
  request context could still be used. Login and sign-out only change the
  session; the application root owns the destination.
- The URL and publishable key are not stored in Git; a secret/service-role key is never used by Flutter.

## Session storage

Supabase Flutter securely persists the session and refresh token on the device.
The app only asks the Supabase client whether a session exists; it does not
store, log, or replay a password. The role is resolved again after launch, so a
previous session never bypasses the admin role check.

## Required Supabase dashboard setting

In Authentication → URL Configuration, add this Additional Redirect URL:

```
backstreetpilates://login-callback/
```

The iOS application declares the corresponding `backstreetpilates` URL scheme.
Keep Confirm email enabled in development and production.

## Local launch

Use the values from Supabase Dashboard → Connect. The publishable key is intended
for client use and is protected by RLS; do not use the secret/service-role key.

```sh
flutter run -d C9F6A868-3B6F-4E6B-9531-69F4480BB6E7 \
  --dart-define=SUPABASE_URL=https://vjzoquvdoyndflcjulun.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Without both values, the app opens but auth submits show a configuration message.

## Review notes

2026-10-30 session-readiness iteration: added a root-level verified-session
gate. A password sign-in and a restored session both validate the signed-in
user before role, approval, member or admin data loads start. This does not
persist or log passwords, and no schema or RLS policy changed. Please verify
on a freshly launched app: sign in once and confirm dashboard data appears
without closing and reopening the app.

User feedback: pending.
Approval: pending.
