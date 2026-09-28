# Progress and continuation

## Current state

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

1. Review the member approved-packages page and its Active / Old status wording.
2. Review the admin dashboard and promote one development user to admin only after approval.
3. Complete Apple Developer/APNs and Firebase configuration, then implement the
   deferred push-notification plan in `docs/NOTIFICATIONS.md`.
4. Review the video-library database foundation before applying its migration.
5. Design the member video-library page after the data model is approved.

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

## Member approved packages

- Added the member-only **My packages** navigation tab. It reads only approved
  membership records available to the signed-in user through existing RLS.
- The page labels currently usable packages **Active**, historical packages
  **Old**, and approved future-start packages **Starts soon**. It is read-only.
- Review notes: `docs/reviews/07-member-approved-packages.md`.
- Verification is pending after this implementation.

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
