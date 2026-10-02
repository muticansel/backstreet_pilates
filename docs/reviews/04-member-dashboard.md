# Page 04: Member dashboard

Status: awaiting user review.

Source: `lib/features/dashboard/dashboard_page.dart`.

## What the screen contains

1. A welcome message and a sign-out control.
2. A current-package card with branch, package, remaining classes, completion progress and expiry date.
3. A package-exploration card that establishes the future purchase entry point.
4. A progress card derived from the member's completed (`attended`) bookings:
   six months of attendance, a current/best weekly consistency series, and
   compact class milestones. It shows a clear empty state before a first
   completed class.
5. A recent-practice card for completed classes.
6. Bottom navigation for Home, Packages and Usage.
7. A branded studio moment: a calm instructor photograph, soft editorial
   overlay and a small organic form before the member's package summary.

## Current data state

The dashboard deliberately uses `DashboardData.preview`. It shows example values
for visual review only: an 8-class Oran package with four remaining classes,
two previous classes. Package and recent-practice values remain preview data.
The progress card is different: it reads only the signed-in member's completed
booking dates through `BookingGateway`; it never substitutes example attendance
when there are no completed bookings.

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
- The progress card rewards regular attendance without making a missed class
  feel punitive: it shows a six-month view, current and best consistency, and
  attainable milestones.
- Each chart bar and milestone has an accessibility label.
- A missing progress record is not an error: the dashboard says that progress
  will appear after the first completed class. A database/load error is shown
  separately.
- The screen scrolls on small devices and retains the app's cream/sage style.
- The dashboard now uses a restrained Georgia display face for headings; the
  rest of the UI stays readable in the platform sans-serif. The studio image is
  an original generated project asset, not a remote image dependency.
- Sign out returns to login.
- The bottom navigation moves between Home, Packages and Usage without recreating the app session.
- The screen does not imply real membership data until the membership and booking model is connected.

## Review notes

User feedback: pending.
Approval: pending.
