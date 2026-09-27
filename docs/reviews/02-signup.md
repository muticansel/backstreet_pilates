# Page 02: Signup

Status: awaiting user review after login.

Source: `lib/features/auth/pages/signup_page.dart`.

## Read in order

1. `SignupPage` owns name, email, password, and confirmation controllers.
2. `dispose` releases all controllers.
3. `_submit` checks the entire form before displaying demo feedback.
4. `build` defines the four inputs and the return-to-login action.

## Behavior to verify

- Name cannot be blank; email must have a plausible format.
- New passwords need at least eight characters and matching confirmation.
- Password visibility can be changed independently for each field.
- Valid submission explicitly states that no account was created.
- Back to login pops the signup route; small screens can scroll through all inputs.

Password length is a prototype rule, not a finalized authentication policy.

## Review notes

User feedback: pending.
Approval: pending.

## Branding update — 2026-09-27

Shared header renamed to Backstreet Pilates at the user’s request.
Existing auth tests and small-screen layout test pass. Page approval remains pending.
