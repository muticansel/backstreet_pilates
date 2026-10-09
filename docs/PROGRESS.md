# Progress and continuation

## Current state

- Added a private-lesson calendar feature locally. Members can see the next
  60 days of 07:00–22:00 one-hour slots, including unavailable time, and send
  an approval request for an open slot. Admins have a weekly calendar for
  pending/approved requests and can block a whole-hour range, including across
  midnight. The proposed migration uses server-side instructor locking to
  prevent overlapping approvals or concurrent requests, and approval creates a
  member push-outbox event. The migration and matching Edge Function source
  are prepared only and have **not** been applied/deployed to Supabase. Review
  `docs/reviews/15-private-lesson-calendar.md` before release.
- Added a member-facing **My private lessons / Özel derslerim** page from the
  Classes tab. It reads only the signed-in member's
  `private_lesson_requests` through existing RLS and displays date, time and
  status for pending, approved, rejected and cancelled requests.
- Prepared `20261010000100_member_private_lesson_request_read.sql` to
  idempotently restore the authenticated member's read policy for private
  lesson requests on incrementally configured Supabase projects. It awaits
  manual application to Supabase.
- Blocked private-lesson ranges can now be deleted from the admin calendar;
  `20261009000200_private_lesson_block_removal.sql` adds the corresponding
  admin-only server RPC. It is prepared only and has not been applied.

- Added the email-confirmation then administrator-approval registration flow.
  A new profile starts as `awaiting_email_confirmation`; an Auth trigger moves
  it to `pending_admin_approval` only after the email link is used. The existing
  admin **Users** page displays that status and offers **Approve**. Approved
  members retain the normal app; unapproved or deactivated members see only a
  status home screen and sign-out option.
- Prepared `20261008000100_member_admin_approval.sql`. It preserves access for
  existing active members, adds the profile approval audit fields, blocks key
  member reads and the cash-purchase RPC for unapproved accounts, and updates
  the profile/Auth triggers. The SQL migration and the updated
  `admin-user-management` Edge Function must be deployed together. Supabase
  Auth email confirmation must remain enabled. See
  `docs/reviews/13-member-registration-approval.md`.

- Replaced the deprecated `RadioListTile.groupValue` and `onChanged` usage in
  the package payment chooser with a `RadioGroup` ancestor. Verification:
  `flutter analyze` now reports no issues. Updated stale dashboard/navigation
  test fixtures and navigation labels to match the current gateways and UI;
  all widget tests pass.

- Member dashboard data now reloads whenever the user returns to **Home** (or
  selects Home again). This prevents attendance and package information
  recorded elsewhere from remaining stale in the dashboard until an app
  restart. Verification: `flutter analyze` reports no issues and all 9 widget
  tests pass.

- Corrected the Android launch crash: the application ID had been renamed to
  `com.muticansel.backstreetpilates`, while `MainActivity` still used Flutter's
  old `com.example.backstreet_pilates` Kotlin package. Android therefore could
  not instantiate the launcher activity. The Kotlin source path and package
  now match the manifest/application ID.

- Push-notification foundation prepared locally: Firebase Core/Messaging,
  authenticated device-token registration/refresh/sign-out removal, an RLS
  migration and a secured FCM-sending Edge Function. The Apple bundle ID and
  Firebase iOS plist are configured locally but ignored by Git. The SQL
  migration, Edge Function secrets, database webhook and physical-iPhone test
  remain explicit deployment steps; see `docs/NOTIFICATIONS.md`.

- User-facing static copy in the member dashboard, authentication layout,
  profile, active-member list, approved-package empty state and selected admin
  summaries now reads from the English/Turkish localization catalog. Dynamic
  count/date copy uses the same localized templates.

- User-facing static copy in the member dashboard, authentication layout,
  profile, active-member list and approved-packages empty state now reads from
  the English/Turkish localization catalog. Dynamic count/date copy uses the
  same localized templates.

- Member dashboard brand pass: added a dedicated serif display treatment,
  refined navigation surface, an original local studio/instructor image with
  quiet organic overlay shapes, and a warmer, more purposeful progress empty
  state. New content is localized in English and Turkish. Review this visual
  update together with `docs/reviews/04-member-dashboard.md`.

- App launch now restores a previously persisted Supabase session and routes it
  through the normal role resolver to member or admin home. Passwords are not
  stored by the app; Supabase Flutter owns the secure session persistence.

- English/Turkish localization foundation added. Users can change the active
  language from the app; selection is session-only for now. See `docs/LOCALIZATION.md`.
- Localization verification: the language-switch widget test and all other 6
  widget tests pass. Analyzer reports only the existing four `RadioListTile`
  deprecation infos in the member package chooser.

- Login and signup source code written; neither page is user-approved.
- Shared theme, layout, validation, password field, and demo dialog written.
- Flutter 3.47.5 / Dart 3.13.4 installed at `/Users/mutic/develop/flutter`.
- SDK PATH configured in ~/.zprofile and ~/.bash_profile; VS Code SDK path configured.
- Xcode 27 and the booted iPhone 17 iOS 26.5 simulator detected.
- iOS platform project generated.
- Code formatted; flutter analyze passes; all three widget tests pass.
- Fixed a brand-label overflow discovered by the 320px screen test using Flexible.
- iOS debug build succeeded and app launched on iPhone 17 (iOS 26.5).
- Login screen screenshot visually checked; no visible overflow.
- Flutter debug session left running for hot reload.
- CocoaPods is absent; the current app has no third-party native plugins.

## Next steps

1. Review the post-class feedback page and its two-touch member record.
2. Review the admin dashboard and promote one development user to admin only after approval.
3. Complete Apple Developer/APNs and Firebase configuration, then implement the
   deferred push-notification plan in `docs/NOTIFICATIONS.md`.
4. Review the video-library database foundation before applying its migration.
5. Design the member video-library page after the data model is approved.

## Planned product improvements — 2026-10-01

The following roadmap is confirmed for subsequent iterations: class
reservations, member progress, post-class feedback, package-ending experience,
admin operations dashboard, stronger brand presentation, and complete English/
Turkish localization. Work begins with reservations; each page remains subject
to user review before it is marked approved.

## Package-ending experience — 2026-10-02

- Added an English/Turkish renewal panel to a member's active package when it
  has one to three remaining class rights. It only appears when an active offer
  matches both the member's current branch and total class count.
- The recommendation uses the earliest matching upcoming offer. Its single
  action creates a cash-payment request through the existing server RPC; no
  membership is granted from Flutter. The existing server duplicate/overlap
  protections remain authoritative, and the button is disabled while the
  request is submitted.
- Package history still renders if the recommendation lookup fails or no
  suitable offer exists. Review the behavior and copy in
  `docs/reviews/11-package-ending-experience.md`.
- Verification: `dart format` completed and all 9 widget tests pass.
  `flutter analyze` reports only the existing four `RadioListTile` deprecation
  infos in the package chooser; the new renewal flow has no findings.

## Admin Today operations — 2026-10-02

- Added an admin-only **Today / Bugün** operations page from the admin landing
  screen. It consolidates today's scheduled classes and occupied seats, today's
  recorded no-shows, packages ending within the next seven days, and all pending
  cash payments. The no-show and payment sections link to their existing action
  queues.
- Prepared `20261002000300_admin_today_operations.sql`. Its one read-only RPC
  uses Istanbul day boundaries and returns the entire snapshot only after the
  server confirms the caller is an admin. Apply it after the fixed-series and
  cash-purchase migrations before using the live screen.
- Review the behavior and wording in `docs/reviews/12-admin-today-operations.md`.
- Verification: `dart format` completed and all 9 widget tests pass. `flutter
  analyze` reports only the existing four `RadioListTile` deprecation infos.

## Required member names — 2026-10-02

- Signup now requires separate first-name and last-name fields and stores them
  in Supabase Auth metadata. The profile page reads, validates and lets members
  edit both values; it maintains the legacy `display_name` as their combined
  name for existing admin and operational lists.
- Prepared `20261002000400_required_profile_names.sql`. It backfills the two
  existing name fields from each profile's display name, requires both database
  columns to be nonblank, and updates the new-user profile trigger. Apply it in
  Supabase SQL Editor before releasing the client change.
- Verification: all 9 widget tests pass. `flutter analyze` reports only the
  existing four `RadioListTile` deprecation infos.

## Admin attendance query correction — 2026-10-02

- Corrected the admin attendance lookup after production-like data verified a
  past, `booked` reservation was hidden despite valid RLS and an admin role.
  The client no longer applies a PostgREST embedded `class_sessions.starts_at`
  filter; it decodes the RLS-protected joined sessions and filters past dates
  locally before loading member names. This preserves the same attendance rule
  while avoiding the unreliable embedded relation filter.
- Separated attendance-save and post-save refresh failures. A completed RPC now
  always reports its saved state; a subsequent reload failure is reported as a
  distinct attendance-load issue instead of incorrectly claiming the save
  failed.
- Added pull-to-refresh to the member dashboard. It reloads completed booking
  dates so a newly recorded attendance result appears without requiring the
  member to sign out or restart the app.

## Member progress preview — 2026-10-01

- Expanded the member dashboard preview with an English/Turkish localized
  progress card: a six-month attendance bar chart, current and best weekly
  consistency series, and small class milestones.
- The progress information remains typed preview data in `DashboardData`; it
  does not read or infer attendance from bookings yet. This keeps the visual
  review honest until attendance/no-show records and their member-facing rules
are implemented.

## Post-class feedback — 2026-10-02

- Added a member-facing, English/Turkish localized feedback history accessed
  from the dashboard. For each attended class, the member records two required
  three-choice ratings: how the class was and its challenge level.
- The completed-class feedback view preserves saved ratings as the member's
  personal history. No free text is collected in this first version.
- Prepared, but did not apply,
  `20261002000100_post_class_feedback.sql`. It allows one feedback record per
  attended booking, restricts member writes to their own records, and allows
  admin read access for instructor/studio follow-up. It depends on the fixed
  booking migration.
- Review the flow and wording in `docs/reviews/10-post-class-feedback.md`.
- Verification: `dart format` and direct Dart analysis pass with only the four
  pre-existing `RadioListTile` deprecation infos. `flutter test` remains
  blocked by pre-existing Flutter SDK startup locks from other active local
  build/run processes.
- Chart bars and milestones include semantic labels for assistive technology.
- Verification: `dart format lib test` completed; all 9 widget tests pass.
  `flutter analyze` has only the existing four `RadioListTile` deprecation
  infos in the package chooser.
- Review the updated dashboard page in `docs/reviews/04-member-dashboard.md`.

### Progress data correction

- Removed the attendance-chart, consistency and milestone preview values. The
  dashboard now reads only the signed-in member's `attended` booking dates and
  derives the last six months, current/best consecutive weeks and milestones
  from those records.
- With no completed bookings, the dashboard displays a localized empty state;
  it does not show invented activity. Loading errors have their own message.
- Added `20261001000400_member_attendance_progress_read.sql`. Apply it after
  the fixed-series booking migration so members can read the dated class session
  behind their own booking; it does not widen access to any other member's data.
- Verification: all 9 widget tests pass. `flutter analyze` has only the four
  pre-existing `RadioListTile` deprecation infos in the package chooser.

### Fixed-series capacity rule

- Oran class series have a maximum capacity of 3 members.
- İncek class series have a maximum capacity of 6 members.
- The upcoming sales-linked reservation migration must enforce these limits on
  the server, rather than trusting an admin-entered capacity in Flutter.

## Member classes and reservation foundation — 2026-10-01

- Added a **My classes / Derslerim** member tab that lists upcoming scheduled
  reservations using a dedicated gateway and safe empty/error states.
- Prepared, but did not apply, `20261001000100_class_booking_foundation.sql`.
  It adds `class_sessions` and `bookings` with authenticated read-only access;
  members can read only their own bookings.
- Client-side booking, cancellation and date changes are intentionally absent
  until the fixed-package cancellation rules are reviewed. Admin scheduling and
  booking are now guarded by atomic server RPCs. See
  `docs/reviews/09-member-classes.md`.
- Rewrote the reservation foundation to use sales-linked fixed class series.
  Admins link an offer to one series and add its dated sessions; they no longer
  select members manually. A cash request holds every future session seat, and
  payment confirmation automatically creates every booking. The server rejects
  incomplete schedules and any series that is full at even one session.
- The previous manual class-session migration had already been applied to the
  development project. `20261001000200_remove_manual_booking_draft.sql` now
  safely clears only an empty old draft, then `20261001000100...` can be run
  manually with the new fixed-series schema. See `docs/FIXED_SERIES_UPGRADE.md`.
- Verification: `dart format lib test` completed and all 9 widget tests pass.
  `flutter analyze` reports only the four existing `RadioListTile` deprecation
  infos in the package chooser; the new reservation flow has no findings.
- Reworked the un-applied reservation migration and the admin schedule page to
  match the confirmed package-sales model. Admin now creates one sellable
  package with branch, price, capacity, total classes, weekly count, first
  class date and weekday/time slots; the server generates every dated session.
  The active offer appears in the member Packages tab without a separate admin
  offer/series-linking step.
- Server capacity validation remains branch-bound (Oran ≤ 3, İncek ≤ 6).
  A cash request holds all sessions; confirmation creates all bookings for the
  user automatically, while the member schedule reads only future bookings.
  Package removal is a safe deactivation that preserves historic records.
- The old manual booking draft and its development data were explicitly
  deleted from the cloud project with the user's confirmation. The current
  migration still needs to be applied before the new admin screen is used.

## Git setup

- Local Git repository initialized on branch `main`.
- Machine-specific VS Code SDK settings excluded from version control.
- Repository-local Git author configured with the user's supplied name and email.
- Initial snapshot prepared with message `Initial Backstreet Pilates app`.
- GitHub origin configured: https://github.com/muticansel/backstreet_pilates.git.
- Remote checked before the initial push: empty, with no existing refs.
- Publish and verify with `git push -u origin main` and `git status -sb`.
- See `docs/GIT_GUIDE.md` for the step-by-step commands.

## Decisions

- App name: Backstreet Pilates; Dart package: backstreet_pilates.
- English UI for the first blueprint; localization remains undecided.
- Supabase selected for the initial backend; all submission feedback remains demo-only.
- The user requested an iOS launch, not a web launch.

## Branding update — 2026-09-27

- Renamed the Dart package to `backstreet_pilates` and updated test imports.
- Login/signup shared header, login prompt, app title, web metadata, and iOS display name now use Backstreet Pilates.
- Workspace folder renamed to `backstreet_pilates`; IDE module references updated. iOS bundle identifier is unchanged to preserve installed app identity.
- Dart formatting, flutter analyze, and all three widget tests passed after renaming.

## Folder rename verification

- Project now lives at `/Users/mutic/Desktop/personal/backstreet_pilates`.
- Flutter generated paths refreshed after cleaning the old build artifacts.
- Analyzer and iOS rebuild passed from the new location.

## Database planning

- `docs/DATABASE.md` records the full design; initial catalog SQL is prepared; user created the cloud project, remote schema status is unverified.
- Confirmed branch-bound packages for Oran and İncek, variable weekly frequency and duration, no-show consumption, future cancellation allowances, and global admin access.
- Supabase/PostgreSQL remains the proposed stack; authentication is still demo-only.
- Confirmed fixed recurring day/time packages for the first release; flexible packages may be added later.
- Database draft now separates scheduling mode, recurring membership slots, dated bookings, and cancellation allowances.
- Proposed atomic activation creates the complete fixed schedule; future-booked credits are distinguished from attended/no-show lessons.
- Package starts automatically on the first scheduled lesson date, with admin override supported; missing that lesson does not postpone the start.
- Draft specifies audited date changes, recalculated end date, reservation consistency checks, and preservation of attendance/credit history.
- Remaining decisions include cancellation terms and studio holiday handling; date boundary conventions are still proposed.

## Initial backend setup

- Installed supabase_flutter 2.17.2.
- Added initial catalog/profile/role migration, inactive fictional seed data, and rollback-based SQL access checks.
- User supplied project URL: https://vjzoquvdoyndflcjulun.supabase.co.
- Screenshot shows project healthy in Seoul (ap-northeast-2).
- Browser access retried: computer-use permissions are still not granted.
- İlk catalog migration kullanıcı tarafından Supabase SQL Editor'da başarıyla uygulandı; tablolar, RLS politikaları ve profil tetikleyicisi oluşturuldu.
- Geliştirme seed verisi kullanıcı tarafından başarıyla uygulandı; iki şube,
  beş pasif örnek paket ve on pasif şube teklifi eklendi.
- Erişim testi Supabase SQL Editor'da hatasız tamamlandı. Test, işlem sonunda
  ROLLBACK yaptığı için geçici kullanıcılar ve rol değişiklikleri kalıcı olmadı.
- Temel Supabase geliştirme kurulumu tamamlandı: katalog verisi, profil
  tetikleyicisi, RLS kuralları ve kullanıcı/admin erişim sınırları doğrulandı.
- Supabase auth integration is implemented locally and awaits page review plus the project's publishable key.
- iOS deep-link scheme `backstreetpilates://login-callback/` is declared; dashboard redirect configuration remains user action.
- Verification: Flutter analyze clean, four widget tests passed, and the iOS simulator build succeeded.
- Real Supabase initialization was verified on the iPhone 17 simulator using the project's publishable key. No key was written to the repository.

## Member dashboard

- Replaced the signed-in placeholder with a member dashboard preview.
- Dashboard presents greeting, remaining class rights, active package, package discovery and recent practice.
- The values are typed preview data, not Supabase membership or booking records.
- Purchase action is explanatory only; no payment or membership write exists.
- Added bottom navigation with Home, Packages and Usage. Packages and Usage are dummy flows; Home holds the dashboard overview.
- Review notes: `docs/reviews/04-member-dashboard.md`.
- Verification: Dart format clean, flutter analyze clean, all 5 widget tests passed, and the iOS simulator build succeeded with Supabase dependencies.

## Admin dashboard

- Sign-in now resolves the current user's database role. `admin` opens a distinct admin dashboard; all other outcomes fall back to the member dashboard.
- The Supabase role resolver reads the signed-in user's own RLS-protected role record and fails closed as a member on error.
- Admin dashboard preview includes monthly sales, active members, an active-package list and a cash-payment/package-grant form.
- Reporting, member and payment data are mock data; the form validates input but does not write a payment or membership.
- Review notes and development-only role setup: `docs/reviews/05-admin-dashboard.md`.
- Verification: Flutter analyze clean, all 6 widget tests passed, and iOS Simulator build artifact regenerated successfully.

## Cash package purchase foundation

- Prepared a member cash-payment request model and an admin-only confirmation RPC.
- The request snapshots the active offer's price, branch and package rules before it enters the admin queue.
- Confirming cash creates one membership. A future requested date remains `pending_start`; a current date becomes `active`.
- Card payment is intentionally excluded until a verified payment-provider flow is implemented.
- Migration and review notes are local only: `supabase/migrations/20260927000300_cash_purchase_requests.sql` and `docs/CASH_PURCHASE_FLOW.md`.
- User applied `20260927000300_cash_purchase_requests.sql` successfully in the development Supabase project.
- First approved catalogue offer: İncek, 8 classes, twice weekly, 4 weeks, 5,000 TRY. Its activation SQL is prepared locally and awaits application.
- Added the admin cash-payment request page. It reads pending requests through
  RLS and calls the existing server-side confirmation RPC; no client-side
  membership write was added. Review notes: `docs/reviews/06-cash-payment-requests.md`.
- Verification: `dart format lib test` and all 6 widget tests pass. `flutter
  analyze` reports only four pre-existing `RadioListTile` deprecation infos in
  the member package chooser; the new admin queue has no analyzer findings.
- Added a follow-up migration that blocks duplicate pending cash requests and
  overlapping copies of the same branch/package. The existing package request
  SnackBar displays the server rejection message. It awaits application to
  Supabase: `20260929000100_prevent_overlapping_package_requests.sql`.

## Member approved packages

- Added the member-only **My packages** navigation tab. It reads only approved
  membership records available to the signed-in user through existing RLS.
- The page labels currently usable packages **Active**, historical packages
  **Old**, and approved future-start packages **Starts soon**. It is read-only.
- Review notes: `docs/reviews/07-member-approved-packages.md`.
- Verification is pending after this implementation.

## Member profile

- Added a normal-member profile entry in the dashboard header and a profile
  screen for name, email, phone, birth date and gender.
- Profile fields use the member's own RLS-protected profile record. Email is
  updated through Supabase Auth and requires the normal confirmation flow;
  passwords are never stored or shown.
- The first version uses a round person/initial avatar. Photo upload is deferred
  until Supabase Storage and privacy rules are reviewed.
- Apply `20260929000200_add_member_profile_fields.sql` to the development
  database before loading or saving birth date and gender. Review notes:
  `docs/reviews/08-member-profile.md`.

## Feedback styling

- Successful cash-request, package-confirmation and profile-save messages now
  use a shared floating sage-green SnackBar. Error states retain the distinct
  terracotta color.

## Push notification plan

- Recorded the requested cash-purchase notification flow for later work:
  admins receive new cash-request notifications, notification taps open the
  approval screen, and the member receives a confirmation notification after
  approval.
- The planned design persists FCM device tokens server-side against the signed-in
  Supabase user; a locally persisted authentication session alone cannot send a
  notification to an offline device.
- Implementation is deferred until the Apple Developer account, APNs setup, and
  Firebase iOS configuration are ready. See `docs/NOTIFICATIONS.md`.

## Auth redirect configuration

- Android now registers the same `backstreetpilates://login-callback/` deep
  link as iOS, so it can receive Supabase email-confirmation redirects.
- The Supabase Dashboard still needs that exact value in Authentication → URL
  Configuration → Additional Redirect URLs. This is required for both iOS and
  Android confirmation testing.

## Registration approval notification

- Added an outbox trigger for the transition to `pending_admin_approval`.
  Every active administrator receives an opaque FCM event after a new account
  has confirmed its email; tapping it opens the existing admin user queue.
- Apply `20261008000200_admin_registration_notifications.sql` after the push
  foundation, class-created notification and registration-approval migrations,
  then redeploy `send-push-notification`. See `docs/NOTIFICATIONS.md`.

## Video library foundation

- Prepared a separate catalogue, ordered-video, access-grant and watch-progress model for paid video series.
- Each series defines its access duration; the initial product value is 365 days.
- Streaming-provider asset identifiers are private. A future Edge Function will issue a short-lived playback URL only after it verifies active access.
- Flutter clients cannot grant themselves access, alter expiry dates or read private playback assets.
- The migration is prepared locally for review and has not been applied to Supabase.
- A rollback-based SQL access test is included for the migration review; it has not been run because the migration is not yet applied.
- Recorded the future production architecture: RevenueCat and native store billing for digital video, verified webhooks and access control in Supabase Edge Functions, `video_player` in Flutter, and Mux or Cloudflare Stream for protected delivery.
- No RevenueCat, player or streaming dependency is installed yet; those are added only with the related reviewed page and backend work.
- Review notes: `docs/VIDEO_LIBRARY.md`.
