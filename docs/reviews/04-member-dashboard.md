# Page 04: Member dashboard

Status: awaiting user review.

Source: `lib/features/dashboard/dashboard_page.dart`.

## What the screen contains

1. A welcome message and a sign-out control.
2. A task-first card directly below the welcome message. It shows the next
   scheduled class and a reserved status, or a clear empty/error state with a
   route to classes or packages.
3. A compact, visual **Today's movement / Bugünün hareketi** card. It adapts
   from the member's existing data: upcoming classes show a reformer warm-up,
   no completed classes show a breathing reset, and members with prior practice
   but no upcoming class see a gentle stretch.
4. A current-package card with branch, package, remaining classes, completion progress and expiry date.
5. A package-exploration area with minimal branch cards for Oran and İncek.
   Each card has a muted location/atmosphere treatment and filters the offers
   without introducing another data request.
6. A progress card derived from the member's completed (`attended`) bookings:
   six months of attendance, a current/best weekly consistency series, and
   compact class milestones. It shows a clear empty state before a first
   completed class.
7. A recent-practice card for completed classes.
8. Bottom navigation for Home, Packages and Usage.
9. A branded studio moment: a calm instructor photograph, soft editorial
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

2026-10-10 design iteration: the dashboard now leads with the member's next
action rather than the studio image. Empty package, progress and practice
states include one contextual next step. Scheduled-class and class-list
statuses use a shared icon-and-label chip; this is the first use of the common
status treatment, not a global approval of all screens.

2026-10-14 design iteration: added the localized, data-driven Today's movement
card. It only uses the already loaded upcoming-class and completed-booking
snapshots, so it does not add another member data request. Loading and data
errors leave the optional card out rather than displaying a generic suggestion.

2026-10-14 package exploration iteration: Oran and İncek are separated with
small, softly tinted location cards instead of treating branch as secondary
metadata. Selecting a card filters the already loaded catalogue; selecting it
again restores all offers. The cards stay hidden when a catalogue has fewer
than two branches.

2026-10-14 empty-catalogue iteration: when there are no available packages,
the page uses a small native-drawn reformer with two slow, periodically moving
orbit lines rather
than a bitmap, video, or animation asset. It does not increase the app bundle
with media, has a static reduce-motion version, and the cash-payment note is
not shown without a package to purchase.

User feedback: pending.
Approval: pending.
