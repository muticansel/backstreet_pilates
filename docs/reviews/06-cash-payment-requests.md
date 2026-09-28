# Page 06: Cash payment requests

Status: awaiting user review.

Sources:

- `lib/features/admin/pages/cash_purchase_requests_page.dart`
- `lib/features/purchases/data/purchase_gateway.dart`
- `lib/features/purchases/data/supabase_purchase_gateway.dart`

## What the page does

An admin sees only `cash_payment_pending` requests, oldest first. Each entry
shows the member, the requested branch-bound package, frozen cash amount,
package rules and requested start date. The admin should verify receipt of cash
outside the app, then choose **Confirm cash payment** and approve the final
confirmation dialog.

Confirmation calls `confirm_cash_membership_purchase` rather than directly
editing any table. The database checks the admin role, locks the pending request,
marks it confirmed and creates exactly one membership. A current/past start is
active; a future start is pending start. A repeat confirmation fails safely and
does not create another membership.

The list refreshes after confirmation and supports pull-to-refresh and the
toolbar refresh button. The app never displays a successful result until the
server RPC has returned successfully.

## Duplicate package requests

The follow-up migration `20260929000100_prevent_overlapping_package_requests.sql`
rejects a second pending request or a new request that overlaps the same
branch-bound package the member already has. The member package chooser already
shows the returned server message as a SnackBar, so no client-side duplicate
state can be bypassed by another device.

## Access control

The navigation entry is shown only after the current account resolves as an
admin. More importantly, the data query is protected by RLS and the confirmation
RPC verifies `private.is_admin()` on the server. Flutter has no service-role key
and cannot grant packages directly.

## Behavior to review

- Is the information sufficient to compare with the cash received in person?
- Is the confirmation wording appropriate for an action that creates a package?
- Are the pending/empty/error states clear?

## Review notes

User feedback: pending.
Approval: pending.
