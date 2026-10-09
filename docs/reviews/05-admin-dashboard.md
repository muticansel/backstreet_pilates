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

The admin home is an operational four-tab dashboard:

1. **Today** is the default tab and shows today's sessions, occupancy,
   no-shows, upcoming package endings and pending payments.
2. **Classes** contains class-series scheduling and attendance entry. A sage
   badge shows the number of today's started bookings still awaiting attendance.
3. **Individual** contains individual-lesson recording and the private-lesson
   calendar.
4. **Management** contains users, cash-payment approval, monthly sales and
   active-member metrics. A terracotta badge marks pending payments because
   they affect membership activation.

Badges are indicators only; the Today tab remains the place to inspect open
work and follow its direct links. All existing target pages, access controls
and server-side writes are unchanged.

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

- Admin users land on Today rather than a long menu of equal-weight cards.
- Badge totals refresh after pull-to-refresh or returning from an action page.
- Classes, Individual and Management expose all prior admin actions.
- A non-admin user cannot reach this page by normal app navigation.

## Review notes

User feedback: pending.
Approval: pending.
