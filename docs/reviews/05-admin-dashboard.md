# Page 05: Admin dashboard

Status: awaiting user review.

Sources:

- `lib/features/account/data/account_role_resolver.dart`
- `lib/features/account/data/supabase_account_role_resolver.dart`
- `lib/features/account/pages/account_home_page.dart`
- `lib/features/admin/pages/admin_dashboard_page.dart`
- `lib/features/admin/pages/active_members_page.dart`
- `lib/features/admin/pages/manual_package_grant_page.dart`

## Access control

After sign-in, the app reads the signed-in user's own `public.user_roles` row.
Only `role = 'admin'` opens this page. A missing row, network error or any role
other than `admin` leads to the normal member dashboard. The client cannot
change a role: the existing RLS rules deny client writes to `user_roles`.

The user-facing role check chooses the correct dashboard. Supabase RLS and the
future server-side payment/membership operations remain the authority for data
access and writes.

## What the page contains

1. Current-month sales total and completed sale count.
2. Total active member count across Oran and İncek.
3. An active-member package list entry point.
4. A cash-payment form entry point that will grant a package after server-side
   validation is implemented.
5. Sign out.

All reporting, member and payment values currently use `AdminDashboardData.preview`.
The form validates basic input but never records a payment or grants a package.
It shows that limitation after submission.

## Development-only admin setup

After reviewing the UI, choose one existing Auth user to act as the development
admin. In the Supabase SQL Editor, use that user's UUID from Authentication →
Users and run:

```sql
update public.user_roles
set role = 'admin'
where user_id = 'replace-with-auth-user-uuid';
```

Do not use signup metadata or Flutter code to grant admin access. To revoke the
role, change `admin` back to `member`. This is a temporary development workflow;
the final admin-management process will be server-side and audited.

## Behavior to review

- Admin users see a substantially different landing page from members.
- The sales and active-member summary is easy to scan.
- The member list and cash-payment form are reached through clear actions.
- The preview-data label prevents treating mock values as real reporting.
- A non-admin user cannot reach this page by normal app navigation.

## Review notes

User feedback: pending.
Approval: pending.
