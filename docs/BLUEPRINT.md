# Project blueprint

## First milestone

Backstreet Pilates is an app concept with cream backgrounds and sage accents.
The initial scope is login and signup UI, form validation, and navigation.
Forms scroll on small screens; wide screens add a Pilates brand panel.
Supabase Flutter is installed for the next integration stage. Current pages remain a local demo without backend requests.

## Code map and review order

1. `lib/main.dart`: starts the app.
2. `lib/app.dart`: configures MaterialApp and its initial page.
3. `lib/theme/app_theme.dart`: shared colors, typography, buttons, and fields.
4. `lib/features/auth/widgets/auth_layout.dart`: responsive page shell.
5. `lib/features/auth/widgets/password_field.dart`: password visibility and input.
6. `lib/features/auth/validation/auth_validators.dart`: client-side input checks.
7. `lib/features/auth/widgets/demo_feedback.dart`: explicit demo result dialog.
8. `lib/features/auth/pages/login_page.dart`: login state and UI.
9. `lib/features/auth/pages/signup_page.dart`: signup state and UI.
10. `test/auth_flow_test.dart`: form, navigation, and small-screen checks.

Each page owns and disposes its text controllers. Flutter's Navigator handles
navigation; local widget state handles password visibility. No state-management
framework is needed for this milestone.

## Later milestones, subject to review

- Choose an authentication provider and implement account creation, sign-in,
  loading states, server errors, session handling, and password recovery.
- Define onboarding, class browsing, and practice tracking with the user.
- Add each page with a matching review document before expanding further.
