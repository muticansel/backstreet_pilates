# Page 07: Member approved packages

Status: awaiting user review.

Sources:

- `lib/features/purchases/pages/approved_packages_page.dart`
- `lib/features/purchases/data/purchase_gateway.dart`
- `lib/features/purchases/data/supabase_purchase_gateway.dart`

## What the page does

The member-only **My packages** tab lists packages created after a studio admin
confirms a cash payment. It reads `user_memberships`, which is RLS-scoped to the
signed-in member (administrators can also read it for management purposes).

Each item shows the package, branch, classes, and a clear status:

- **Active** when the membership is active and its exclusive end date is still in the future.
- **Old** when it is expired, cancelled, or has otherwise ended.
- **Starts soon** for an approved package whose start date is in the future.

The page has loading, empty, error/retry, and pull-to-refresh states. It is
read-only: it cannot approve, activate, alter, or purchase a package.

## Behavior to review

- Is the separate **My packages** tab the preferred place for the full approved-package history?
- Is the Active / Old wording clear? Future approved packages are labelled Starts soon to avoid calling them old.
- Are the package details sufficient for members?

## Review notes

User feedback: pending.
Approval: pending.
