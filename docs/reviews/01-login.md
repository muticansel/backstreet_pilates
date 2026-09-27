# Page 01: Login

Status: awaiting user review.

Source: `lib/features/auth/pages/login_page.dart`.

## Read in order

1. `LoginPage` creates local state.
2. Controllers hold email and password only in memory and are disposed with the page.
3. `_submit` validates fields and opens the demo dialog.
4. `build` composes the shared layout, form, and navigation button.
5. The signup link clears the password and pushes `SignupPage`.

## Behavior to verify

- Empty or malformed email shows an inline error.
- Empty password is rejected; visibility toggle works.
- Valid form shows demo feedback without authenticating.
- Keyboard submission works and fields remain reachable on small screens.
- Signup link opens signup; returning restores login.

## Review notes

User feedback: pending.
Approval: pending.

## Verification on 2026-09-27

Analyzer and all three auth widget tests pass. Shared brand text now uses Flexible
to prevent overflow at 320px width. Source formatting was applied with Dart.

## Branding update — 2026-09-27

Shared header renamed to Backstreet Pilates at the user’s request.
Existing auth tests and small-screen layout test pass. Page approval remains pending.
