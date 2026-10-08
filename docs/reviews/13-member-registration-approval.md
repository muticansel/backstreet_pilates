# Member registration approval

## Intended flow

1. A visitor registers with their name, email address and password.
2. Supabase sends the existing email-confirmation link.
3. Confirming that link moves the profile into the administrator approval queue.
4. An administrator opens **Users** and selects **Approve** for that confirmed registration.
5. Only then can the member access packages, classes and other member actions.

Before approval, the signed-in account has a deliberately limited home screen
explaining whether email confirmation or studio approval is still required. It
cannot navigate to member actions. The accompanying database migration also
blocks the member-facing reads and cash-purchase RPC for unapproved accounts,
so this is not only a Flutter navigation restriction.

## Deployment checklist

- Apply `20261008000100_member_admin_approval.sql` after the existing profile,
  purchase and fixed-series migrations.
- Deploy `supabase/functions/admin-user-management` after applying the SQL.
- In Supabase Auth, keep **Confirm email** enabled and ensure the
  `backstreetpilates://login-callback/` redirect URL is allowed.
- Review a new signup: it must not show in the approval queue until its email
  link has been used.

## Review requested

Confirm the waiting-screen wording and whether the existing **Users** entry is
the desired place for administrators to approve registrations.
