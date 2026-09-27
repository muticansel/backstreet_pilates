# Progress and continuation

## Current state

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

1. Review shared foundation and login code with the user.
2. Record feedback before beginning further page work.

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
- Authentication provider remains undecided; all submission feedback is demo-only.
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

- Added `docs/DATABASE.md` as a review draft; no SQL or backend provisioned.
- Confirmed branch-bound packages for Oran and İncek, variable weekly frequency and duration, no-show consumption, future cancellation allowances, and global admin access.
- Supabase/PostgreSQL remains the proposed stack; authentication is still demo-only.
- Confirmed fixed recurring day/time packages for the first release; flexible packages may be added later.
- Database draft now separates scheduling mode, recurring membership slots, dated bookings, and cancellation allowances.
- Proposed atomic activation creates the complete fixed schedule; future-booked credits are distinguished from attended/no-show lessons.
- Package starts automatically on the first scheduled lesson date, with admin override supported; missing that lesson does not postpone the start.
- Draft specifies audited date changes, recalculated end date, reservation consistency checks, and preservation of attendance/credit history.
- Remaining decisions include cancellation terms and studio holiday handling; date boundary conventions are still proposed.
