# Page 04: Member dashboard

Status: awaiting user review.

Source: `lib/features/dashboard/dashboard_page.dart`.

## What the screen contains

1. A welcome message and a sign-out control.
2. A current-package card with branch, package, remaining classes, completion progress and expiry date.
3. A package-exploration card that establishes the future purchase entry point.
4. A recent-practice card for completed classes.
5. Bottom navigation for Home, Packages and Usage.

## Current data state

The dashboard deliberately uses `DashboardData.preview`. It shows example values
for visual review only: an 8-class Oran package with four remaining classes and
two previous classes. It neither reads nor writes purchase, membership, class or
booking data. Those tables have not been implemented yet.

The preview is kept in a typed model, rather than scattered hard-coded widget
text, so the later membership repository can provide the same screen structure
with Supabase data.

The package button opens an explanatory sheet only. It does not offer a sale,
charge a card, or change membership data.

Packages and Usage are intentionally dummy flows for the current review. Packages
shows future package options; Usage identifies the future history area. Home is
the initial selected tab and contains the dashboard overview.

## Behavior to review

- The member can see remaining use rights, current package and recent practice at a glance.
- The package card makes the branch and expiry date easy to identify.
- The screen scrolls on small devices and retains the app's cream/sage style.
- Sign out returns to login.
- The bottom navigation moves between Home, Packages and Usage without recreating the app session.
- The screen does not imply real membership data until the membership and booking model is connected.

## Review notes

User feedback: pending.
Approval: pending.
