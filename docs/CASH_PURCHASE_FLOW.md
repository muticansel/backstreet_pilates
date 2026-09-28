# Cash package purchase flow

Status: migration applied to the development Supabase project. The member
request screen and admin confirmation queue are connected locally; they await
UI review against a development admin account.

## Member flow

1. Member chooses an active package offer. Each offer is already bound to one
   branch, such as `Oran · 8 classes / 8 weeks`; the member never chooses a
   branch separately.
2. Member selects the earliest acceptable start date.
3. Member selects Cash or Credit card.
4. Cash calls `request_cash_membership_purchase`; the server snapshots the offer
   price and package rules, then writes `cash_payment_pending`.
5. Credit card will use a payment-provider flow later. It must not create a
   cash request or mark a membership paid.
6. The server rejects a duplicate pending request and any request that would
   overlap an active or future-start package for the same branch and plan. The
   app closes the request dialog and shows the server's message in a floating,
   terracotta error toast/SnackBar.

## Admin flow

1. Admin sees pending cash requests.
2. After receiving cash, admin calls `confirm_cash_membership_purchase`.
3. The server marks the request confirmed and creates exactly one membership.
4. A requested date today or earlier creates an `active` membership; a future
   date creates `pending_start`. Booking/scheduling will later refine the first
   actual class date.

Users cannot mark their own cash payment paid, edit the frozen price, or create
memberships directly. Both server functions validate the signed-in user and are
safe against a duplicate confirmation.

## Before applying

- Review `supabase/migrations/20260927000300_cash_purchase_requests.sql`.
- Apply `supabase/migrations/20260929000100_prevent_overlapping_package_requests.sql`
  after the cash-purchase migration to enforce duplicate-package prevention.
- At least one branch-bound offer and its plan must be active before a member
  can submit a request. The existing development seed offers are deliberately
  inactive.
- The initial Flutter package screen still needs to be connected to this flow.

## First approved offer

`supabase/migrations/20260927000400_activate_incek_8_2_4_offer.sql` activates
only this offer: **İncek · 8 ders · haftada 2 · 4 hafta · 5.000 TL**. It also
removes the `ÖRNEK:` label from that global plan. No Oran offer is activated.
