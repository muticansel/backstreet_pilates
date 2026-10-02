# Page 11: Package-ending experience

Status: awaiting user review.

Sources:

- `lib/features/purchases/pages/approved_packages_page.dart`
- `lib/features/purchases/data/purchase_gateway.dart`
- `lib/features/purchases/data/supabase_purchase_gateway.dart`

## What the page does

Within **My packages**, an active package with one to three remaining classes
now shows a gentle renewal panel. The panel recommends the earliest active
offer from the same branch with the same number of classes, so it preserves the
member's current studio rhythm instead of presenting an unrelated package.

The member can select **Request cash renewal** once. That single interaction
uses the existing `request_cash_membership_purchase` RPC with the suggested
offer's first-class date. The server remains the source of truth: its existing
duplicate and overlapping-package protections can reject an unsuitable request,
and the app shows that message. While a request is being created, every renewal
button is disabled to avoid double taps.

If there is no matching active offer, no renewal panel is shown. Package history
continues to load even if the offer lookup is unavailable.

## Behavior to review

- Is the one-to-three-class threshold the right moment for the reminder?
- Should a suitable renewal be limited to the same branch and same class count?
- Is a direct cash-request action appropriate without a confirmation dialog?

## Review notes

User feedback: pending.
Approval: pending.
